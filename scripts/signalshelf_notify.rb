#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'shellwords'
require 'time'

def debug_log(message)
  return unless ENV['SIGNALSHELF_DEBUG']

  warn(message)
end

def read_payload
  return ARGV[0] if ARGV[0] && !ARGV[0].empty?

  $stdin.read
end

def parse_payload(raw)
  JSON.parse(raw)
rescue JSON::ParserError => e
  debug_log("signalshelf_notify: JSON parse error: #{e.message}")
  {}
end

def fetch_value(hash, *keys)
  keys.each do |key|
    return hash[key] if hash.is_a?(Hash) && hash.key?(key)
  end
  nil
end

def retry_attempts
  attempts = ENV.fetch('SIGNALSHELF_RETRY_ATTEMPTS', '2').to_i
  attempts = 1 if attempts < 1
  attempts
end

def retry_delay_seconds
  ms = ENV.fetch('SIGNALSHELF_RETRY_DELAY_MS', '200').to_i
  ms = 0 if ms.negative?
  ms / 1000.0
end

def with_short_retry(attempts: retry_attempts, delay: retry_delay_seconds)
  last = nil
  attempts.times do |index|
    last = yield
    return last if last

    sleep(delay) if index < attempts - 1 && delay.positive?
  end
  last
end

def notify_command
  raw = ENV['SIGNALSHELF_NOTIFY_COMMAND'].to_s.strip
  return nil if raw.empty?

  Shellwords.split(raw)
end

def notify_send_available?
  ENV.fetch('PATH', '').split(File::PATH_SEPARATOR).any? do |dir|
    File.executable?(File.join(dir, 'notify-send'))
  end
end

def send_notification(title, message)
  cmd = notify_command
  if cmd
    system(*cmd, title, message)
    return
  end

  return unless notify_send_available?

  system('notify-send', title, message)
end

def truncate_text(text, max_length)
  return '' if text.nil?

  value = text.to_s.strip
  value.length > max_length ? value[0, max_length] : value
end

def extract_last_user_message(messages)
  return nil unless messages.is_a?(Array)

  messages.reverse_each do |message|
    next unless message.is_a?(Hash)

    role = fetch_value(message, 'role', 'type')
    next unless role.to_s == 'user'

    content = fetch_value(message, 'content', 'text', 'message')
    return extract_text_from_content(content) if content
  end

  nil
end

def normalize_content(value)
  return '' if value.nil?

  if value.is_a?(Array)
    value.filter_map { |item| item.is_a?(Hash) ? item['text'] : item.to_s }.join("\n")
  else
    value.to_s
  end
end

def extract_text_from_content(content)
  return '' if content.nil?

  if content.is_a?(Array)
    content.filter_map do |item|
      next item['text'] if item.is_a?(Hash) && item['text']

      if item.is_a?(Hash) && item['type'] == 'output_text'
        item['text'].to_s
      else
        item.to_s
      end
    end.join("\n")
  elsif content.is_a?(Hash)
    content['text'].to_s
  else
    content.to_s
  end
end

def find_session_by_id(root, session_id)
  return nil if session_id.nil? || session_id.to_s.empty?

  pattern = File.join(root, '**', "*#{session_id}*.jsonl")
  Dir.glob(pattern).max_by { |path| File.mtime(path) }
end

def read_session_meta(path)
  return nil unless path && File.exist?(path)

  File.open(path) do |file|
    line = file.gets
    return nil unless line

    JSON.parse(line)
  rescue JSON::ParserError
    nil
  end
end

def agent_source_from_meta(meta)
  return nil unless meta.is_a?(Hash) && meta['type'] == 'session_meta'

  payload = meta['payload'].is_a?(Hash) ? meta['payload'] : {}
  originator = payload['originator'].to_s
  base_instructions = payload['base_instructions'].is_a?(Hash) ? payload['base_instructions']['text'].to_s : ''

  return 'codex' if originator.include?('codex') || base_instructions.include?('Codex')
  return 'claude' if base_instructions.include?('Claude')

  provider = payload['model_provider'].to_s
  provider.empty? ? nil : provider
end

def find_recent_session_by_cwd(root, cwd, limit: 50)
  files = Dir.glob(File.join(root, '**', '*.jsonl'))
  files = files.sort_by { |path| File.mtime(path) }.reverse

  files.first(limit).each do |path|
    meta = read_session_meta(path)
    next unless meta.is_a?(Hash)
    next unless meta['type'] == 'session_meta'

    payload = meta['payload'].is_a?(Hash) ? meta['payload'] : {}
    next if cwd && payload['cwd'] && payload['cwd'] != cwd

    return path
  end

  files.first
end

def select_recent_session_message(root, cwd, limit: 30)
  files = Dir.glob(File.join(root, '**', '*.jsonl'))
  files = files.sort_by { |path| File.mtime(path) }.reverse

  best = nil
  files.first(limit).each do |path|
    meta = read_session_meta(path)
    next unless meta.is_a?(Hash)
    next unless meta['type'] == 'session_meta'

    payload = meta['payload'].is_a?(Hash) ? meta['payload'] : {}
    next if cwd && payload['cwd'] && payload['cwd'] != cwd

    message = extract_last_assistant_message(path)
    next unless message && message['text']

    timestamp = message['timestamp']
    parsed_time = begin
      Time.parse(timestamp.to_s)
    rescue ArgumentError
      nil
    end

    if best.nil? || (parsed_time && best[:time] && parsed_time > best[:time]) || (best[:time].nil? && parsed_time)
      best = { path: path, message: message, time: parsed_time }
    end
  end

  best
end

def extract_last_assistant_message(path)
  return nil unless path && File.exist?(path)

  last = nil
  File.foreach(path) do |line|
    event = JSON.parse(line)
    next unless event.is_a?(Hash)
    next unless event['type'] == 'response_item'

    payload = event['payload']
    next unless payload.is_a?(Hash)
    next unless payload['type'] == 'message'
    next unless payload['role'] == 'assistant'

    content = extract_text_from_content(payload['content'])
    next if content.strip.empty?

    last = { 'text' => content, 'timestamp' => event['timestamp'] }
  rescue JSON::ParserError
    next
  end

  last
end

def extract_text_from_output(raw)
  return '' if raw.nil?

  if raw.is_a?(String)
    trimmed = raw.strip
    if trimmed.start_with?('{', '[')
      begin
        parsed = JSON.parse(trimmed)
        return extract_text_from_output(parsed)
      rescue JSON::ParserError
        return raw
      end
    end
    return raw
  end

  if raw.is_a?(Hash)
    return extract_text_from_output(raw['content']) if raw.key?('content')
    return extract_text_from_output(raw['output']) if raw.key?('output')
    return raw['text'].to_s if raw.key?('text')

    return raw.to_s
  end

  if raw.is_a?(Array)
    parts = raw.map { |item| extract_text_from_output(item) }
    parts = parts.reject { |item| item.nil? || item.empty? }
    return parts.join("\n")
  end

  raw.to_s
end

def extract_task_output(path)
  return nil unless path && File.exist?(path)

  task_calls = {}
  last_result = nil

  File.foreach(path) do |line|
    event = JSON.parse(line)
    next unless event.is_a?(Hash)
    next unless event['type'] == 'response_item'

    payload = event['payload']
    next unless payload.is_a?(Hash)

    case payload['type']
    when 'function_call'
      name = payload['name'].to_s
      next unless name.casecmp('task').zero?

      call_id = payload['call_id'].to_s
      next if call_id.empty?

      args = payload['arguments']
      if args.is_a?(String)
        begin
          args = JSON.parse(args)
        rescue JSON::ParserError
          args = {}
        end
      end
      args = {} unless args.is_a?(Hash)

      task_calls[call_id] = args.merge('_call_id' => call_id)
    when 'function_call_output'
      call_id = payload['call_id'].to_s
      next if call_id.empty?
      next unless task_calls.key?(call_id)

      args = task_calls[call_id] || {}
      output_text = extract_text_from_output(payload['output']).to_s
      next if output_text.strip.empty?

      last_result = {
        output: output_text,
        agent_type: args['subagent_type'] || args['agent_type'] || args['agent'],
        description: args['description'],
        call_id: args['_call_id'],
        run_in_background: args['run_in_background'],
        args: args
      }
    end
  rescue JSON::ParserError
    next
  end

  last_result
end

AGENT_TYPE_PATTERNS = [
  /\[AGENT:([^\]]+)\]/,
  /🗣️\s*\*{0,2}([A-Za-z0-9_-]+):?\*{0,2}\s*/i,
  /Sub-agent\s+([A-Za-z0-9_-]+)\s+completed/i,
  /(?:^|\n)\s*([A-Za-z0-9_-]+)\s+completed\b/i,
  /Agent:\s*([A-Za-z0-9_-]+)/
].freeze

def extract_agent_type(text)
  return nil if text.nil? || text.empty?

  AGENT_TYPE_PATTERNS.each do |pattern|
    match = text.match(pattern)
    return match[1] if match
  end

  nil
end

def extract_agent_type_from_messages(messages)
  return nil unless messages.is_a?(Array)

  messages.each do |message|
    content = normalize_content(message['content'])
    candidate = extract_agent_type(content)
    return candidate if candidate
  end

  nil
end

def normalize_agent_type(value)
  return nil if value.nil?

  key = value.to_s.downcase.strip
  return nil if key.empty?

  mapping = {
    'research' => 'researcher',
    'researcher' => 'researcher',
    'engineer' => 'engineer',
    'engineering' => 'engineer',
    'architect' => 'architect',
    'designer' => 'designer',
    'design' => 'designer',
    'pentest' => 'pentester',
    'pentester' => 'pentester',
    'security' => 'pentester'
  }

  mapping[key] || key
end

def category_for(agent_type)
  case agent_type.to_s.downcase
  when 'researcher'
    'RESEARCH'
  when 'architect'
    'DECISION'
  when 'engineer'
    'IMPLEMENTATION'
  when 'designer'
    'DESIGN'
  when 'pentester'
    'SECURITY'
  else
    'RESEARCH'
  end
end

def completion_line(text)
  return '' if text.nil? || text.empty?

  line = text.lines.find { |l| l.include?('COMPLETED') } || text.lines.first
  line ? line.strip : ''
end

def extract_completion_message(text)
  return { message: nil, agent_type: nil } if text.nil? || text.empty?

  patterns = [
    # NEW: 🗣️ AgentName: message
    /🗣️\s*\*{0,2}([A-Za-z0-9_-]+):?\*{0,2}\s*(.+?)(?:\n|$)/i,
    # LEGACY: 🎯 COMPLETED: [AGENT:type] message (with/without markdown)
    /\*+🎯\s*COMPLETED:\*+\s*\[AGENT:([A-Za-z0-9_-]+)\]\s*(.+?)(?:\n|$)/i,
    /🎯\s*COMPLETED:\s*\[AGENT:([A-Za-z0-9_-]+)\]\s*(.+?)(?:\n|$)/i,
    /COMPLETED:\s*\[AGENT:([A-Za-z0-9_-]+)\]\s*(.+?)(?:\n|$)/i,
    # Multi-line patterns
    /🎯\s*COMPLETED[\s\n]+\[AGENT:([A-Za-z0-9_-]+)\]\s*(.+?)(?:\n|$)/i,
    /##\s*🎯\s*COMPLETED[\s\n]+\[AGENT:([A-Za-z0-9_-]+)\]\s*(.+?)(?:\n|$)/i,
    # OLD: [AGENT:type] I completed ...
    /\[AGENT:([A-Za-z0-9_-]+)\]\s*I\s+completed\s+(.+?)(?:\.|!|\n|$)/i,
    # Generic: Sub-agent X completed ...
    /Sub-agent\s+([A-Za-z0-9_-]+)\s+completed\s+(.+?)(?:\.|!|\n|$)/i
  ]

  patterns.each do |pattern|
    match = text.match(pattern)
    next unless match

    agent_type = match[1]
    message = match[2].to_s.strip
    message = message.sub(/^I\s+completed\s+/i, '')
    message = message.sub(/^(the\s+)?requested\s+task$/i, '')
    return { message: message, agent_type: agent_type } unless message.empty?
  end

  # Generic fallbacks (no agent type)
  generic_patterns = [
    /🗣️\s*(.+?)(?:\n|$)/i,
    /\*+🎯\s*COMPLETED:\*+\s*(.+?)(?:\n|$)/i,
    /🎯\s*COMPLETED:\s*(.+?)(?:\n|$)/i,
    /COMPLETED:\s*(.+?)(?:\n|$)/i
  ]

  generic_patterns.each do |pattern|
    match = text.match(pattern)
    next unless match

    message = match[1].to_s.strip
    message = message.sub(/^I\s+completed\s+/i, '')
    return { message: message, agent_type: nil } unless message.empty?
  end

  { message: nil, agent_type: nil }
end

def slugify(text, max_length = 60)
  slug = text.to_s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-+|-+$/, '')
  slug = slug[0, max_length] if slug.length > max_length
  slug = slug.gsub(/-+$/, '')
  slug = 'capture' if slug.empty?
  slug
end

def build_frontmatter(fields)
  lines = ['---']
  fields.each do |key, value|
    next if value.nil? || value.to_s.empty?

    lines << "#{key}: #{value}"
  end
  lines << '---'
  lines.join("\n")
end

def ensure_unique_path(path)
  return path unless File.exist?(path)

  base = path.delete_suffix('.md')
  index = 2
  loop do
    candidate = "#{base}-#{index}.md"
    return candidate unless File.exist?(candidate)

    index += 1
  end
end

def append_observability_events(events)
  root = ENV.fetch('SIGNALSHELF_ROOT', '~/.agent-kit/MEMORY')
  root = File.expand_path(root)
  state_dir = File.join(root, 'STATE')
  FileUtils.mkdir_p(state_dir)
  path = File.join(state_dir, 'observability-events.jsonl')
  File.open(path, 'a') do |file|
    events.each { |event| file.puts(JSON.generate(event)) }
  end
rescue StandardError => e
  debug_log("signalshelf_notify: observability append failed: #{e.message}")
end

def write_capture(content, options)
  root = options.fetch(:root)
  category = options.fetch(:category)
  timestamp = options.fetch(:timestamp)
  agent_label = options.fetch(:agent_label)
  description = options.fetch(:description)

  month_dir = timestamp.strftime('%Y-%m')
  dir = File.join(root, category, month_dir)
  FileUtils.mkdir_p(dir)

  stamp = timestamp.strftime('%Y-%m-%d-%H%M%S')
  filename = "#{stamp}_AGENT-#{agent_label}_#{category}_#{description}.md"
  path = ensure_unique_path(File.join(dir, filename))
  File.write(path, content)
end

def run_signalshelf_notify
  payload = parse_payload(read_payload)
  data = fetch_value(payload, 'data') || {}
  event_type = fetch_value(payload, 'type', 'event', 'name')

  last_message = fetch_value(
    data,
    'last-assistant-message',
    'last_assistant_message',
    'lastAssistantMessage'
  )
  input_messages = fetch_value(data, 'input-messages', 'input_messages', 'inputMessages') || []
  cwd = fetch_value(payload, 'cwd') || fetch_value(data, 'cwd')
  thread_id = fetch_value(data, 'thread-id', 'thread_id', 'threadId')
  turn_id = fetch_value(data, 'turn-id', 'turn_id', 'turnId')

  sessions_root = ENV.fetch('CODEX_SESSIONS_DIR', '~/.codex/sessions')
  sessions_root = File.expand_path(sessions_root)
  session_message = nil
  session_path = with_short_retry { find_session_by_id(sessions_root, thread_id) }
  session_meta = read_session_meta(session_path)
  session_message = with_short_retry { extract_last_assistant_message(session_path) } if session_path

  if session_message.nil?
    recent = select_recent_session_message(sessions_root, cwd)
    session_path = recent[:path] if recent
    session_message = recent[:message] if recent
    session_meta = read_session_meta(session_path)
  end

  session_path ||= with_short_retry { find_recent_session_by_cwd(sessions_root, cwd) }
  session_message ||= with_short_retry { extract_last_assistant_message(session_path) } if session_path
  session_meta ||= read_session_meta(session_path)

  task_result = with_short_retry { extract_task_output(session_path) }
  task_description = task_result ? task_result[:description] : nil
  task_agent_type = task_result ? task_result[:agent_type] : nil
  task_run_in_background = task_result ? task_result[:run_in_background] : nil
  task_call_id = task_result ? task_result[:call_id] : nil

  output_body = if task_result && task_result[:output]
                  task_result[:output].strip
                elsif session_message && session_message['text']
                  session_message['text'].strip
                else
                  last_message.to_s.strip
                end

  completion_info = extract_completion_message(output_body)

  agent_type = completion_info[:agent_type]
  agent_type ||= task_agent_type
  agent_type ||= extract_agent_type(output_body)
  agent_type ||= extract_agent_type(last_message)
  agent_type ||= extract_agent_type_from_messages(input_messages)
  agent_type = normalize_agent_type(agent_type)
  agent_source = agent_source_from_meta(session_meta)
  agent_label = (agent_type || agent_source || 'assistant').downcase
  category = category_for(agent_type)
  completion = completion_info[:message] || completion_line(output_body)
  completion = task_description.to_s if completion.to_s.empty? && task_description
  description = slugify(completion)

  timestamp = Time.now
  timestamp_label = timestamp.strftime('%Y-%m-%d %H:%M:%S %Z')

  frontmatter = build_frontmatter(
    'capture_type' => category,
    'timestamp' => timestamp_label,
    'executor' => agent_source || 'assistant',
    'agent_type' => agent_type,
    'agent_source' => agent_source,
    'agent_completion' => completion,
    'task_description' => task_description,
    'task_subagent_type' => task_agent_type,
    'task_run_in_background' => task_run_in_background,
    'task_call_id' => task_call_id,
    'event_type' => event_type,
    'thread_id' => thread_id,
    'turn_id' => turn_id,
    'cwd' => cwd,
    'transcript_path' => session_path,
    'source' => 'codex-notify'
  )

  title = completion.empty? ? "#{category}: SignalShelf Capture" : "#{category}: #{completion}"

  metadata_lines = []
  metadata_lines << "**Thread:** #{thread_id}" if thread_id
  metadata_lines << "**Turn:** #{turn_id}" if turn_id
  metadata_lines << "**Cwd:** #{cwd}" if cwd
  metadata_lines << "**Transcript:** #{session_path}" if session_path
  metadata_lines << "**Source:** #{agent_source}" if agent_source
  metadata_lines << "**Agent Type:** #{agent_type}" if agent_type
  metadata_lines << "**Task Description:** #{task_description}" if task_description
  metadata_lines << "**Task Subagent:** #{task_agent_type}" if task_agent_type
  metadata_lines << "**Task Background:** #{task_run_in_background}" unless task_run_in_background.nil?
  metadata_lines << "**Task Call ID:** #{task_call_id}" if task_call_id

  content = [
    frontmatter,
    '',
    "# #{title}",
    '',
    "**Agent:** #{agent_label}",
    "**Completed:** #{timestamp_label}",
    '',
    '---',
    '',
    '## Agent Output',
    '',
    output_body.empty? ? '(empty)' : output_body,
    '',
    '---',
    '',
    '## Metadata',
    '',
    metadata_lines.empty? ? '(none)' : metadata_lines.join("\n")
  ].join("\n")

  root = ENV.fetch('SIGNALSHELF_ROOT', '~/.agent-kit/MEMORY')
  root = File.expand_path(root)

  timestamp_ms = (Time.now.to_f * 1000).to_i
  events_to_emit = []

  user_message = extract_last_user_message(input_messages)
  if user_message && !user_message.strip.empty?
    events_to_emit << {
      source_app: agent_source || 'codex',
      session_id: thread_id || 'unknown',
      hook_event_type: 'UserPromptSubmit',
      summary: truncate_text(user_message, 100),
      agent_name: 'user',
      timestamp: timestamp_ms,
      payload: {
        prompt: truncate_text(user_message, 500)
      }
    }
  end

  if task_result
    events_to_emit << {
      source_app: agent_source || 'codex',
      session_id: thread_id || 'unknown',
      hook_event_type: 'PreToolUse',
      summary: 'Task invoked',
      agent_name: agent_type,
      timestamp: timestamp_ms + 1,
      payload: {
        tool_name: 'Task',
        tool_input: task_result[:args]
      }
    }

    if task_result[:output]
      events_to_emit << {
        source_app: agent_source || 'codex',
        session_id: thread_id || 'unknown',
        hook_event_type: 'PostToolUse',
        summary: 'Task result received',
        agent_name: agent_type,
        timestamp: timestamp_ms + 2,
        payload: {
          tool_name: 'Task',
          tool_result: truncate_text(task_result[:output], 500)
        }
      }
    end
  end

  if output_body && !output_body.strip.empty?
    events_to_emit << {
      source_app: agent_source || 'codex',
      session_id: thread_id || 'unknown',
      hook_event_type: 'Stop',
      summary: truncate_text(output_body, 100),
      agent_name: agent_type,
      timestamp: timestamp_ms + 3,
      payload: {
        response: truncate_text(output_body, 500)
      }
    }
  end

  observability_event = {
    source_app: agent_source || 'codex',
    session_id: thread_id || 'unknown',
    hook_event_type: event_type || 'agent-turn-complete',
    summary: completion,
    agent_name: agent_type,
    timestamp: timestamp_ms + 4,
    payload: {
      cwd: cwd,
      transcript_path: session_path,
      task_description: task_description,
      task_subagent_type: task_agent_type,
      task_run_in_background: task_run_in_background,
      task_call_id: task_call_id
    }.compact
  }

  write_capture(
    content,
    {
      root: root,
      category: category,
      timestamp: timestamp,
      agent_label: agent_label,
      description: description
    }
  )

  events_to_emit << observability_event
  append_observability_events(events_to_emit)

  if task_run_in_background == true
    notify_title = 'SignalShelf background agent'
    notify_message = completion.empty? ? 'Background agent completed' : completion
    send_notification(notify_title, notify_message)
  end
rescue StandardError => e
  debug_log("signalshelf_notify: error: #{e.message}")
ensure
  exit 0
end

run_signalshelf_notify if __FILE__ == $PROGRAM_NAME
