# frozen_string_literal: true

require 'json'

class ProjectEventStore
  MAX_EVENTS = 1000
  MAX_FILES = 50

  def self.instance
    @instance ||= new
  end

  def enabled?
    projects_dir && File.directory?(projects_dir)
  end

  def source_label
    projects_dir
  end

  def refresh!
    return unless enabled?

    recent_files.each do |file_path|
      read_new_events(file_path).each do |event|
        event['id'] ||= next_id
        @events << Event.new(event)
      end
    end

    trim_events
  end

  def events
    @events.sort_by { |event| event.timestamp.to_i }.reverse
  end

  def max_events
    MAX_EVENTS
  end

  private

  def initialize
    @events = []
    @file_positions = {}
    @next_id = 1
  end

  def projects_dir
    env = ENV['AGENTMEM_PROJECTS_DIR']
    return nil if env.nil? || env.empty?

    File.expand_path(env)
  end

  def recent_files
    Dir.glob(File.join(projects_dir, '**', '*.jsonl'))
       .map { |path| [path, File.mtime(path).to_i] }
       .sort_by { |(_, mtime)| -mtime }
       .first(MAX_FILES)
       .map(&:first)
  end

  def read_new_events(file_path)
    return [] unless File.file?(file_path)

    last_position = @file_positions[file_path] || 0
    content = File.read(file_path)
    new_content = content.byteslice(last_position..)
    @file_positions[file_path] = content.bytesize

    return [] if new_content.nil? || new_content.strip.empty?

    new_events = []
    new_content.split("\n").each do |line|
      next if line.strip.empty?

      begin
        entry = JSON.parse(line)
      rescue JSON::ParserError
        next
      end

      event = parse_projects_entry(entry)
      new_events << event if event
    end

    new_events
  rescue Errno::ENOENT, Errno::EACCES
    []
  end

  def parse_projects_entry(entry)
    return nil unless entry.is_a?(Hash)

    entry_type = entry['type']
    return nil if entry_type == 'queue-operation' || entry_type == 'summary'

    timestamp_value = entry['timestamp'] || Time.now.iso8601
    session_id = entry['sessionId'] || 'unknown'

    timestamp_ms = parse_timestamp_ms(timestamp_value)
    base_event = {
      'source_app' => 'claude-code',
      'session_id' => session_id,
      'timestamp' => timestamp_ms
    }

    if entry_type == 'user' && entry.dig('message', 'role') == 'user'
      return build_user_event(entry, base_event)
    end

    if entry_type == 'assistant' && entry.dig('message', 'role') == 'assistant'
      return build_assistant_event(entry, base_event)
    end

    nil
  end

  def build_user_event(entry, base_event)
    content = entry.dig('message', 'content')

    if content.is_a?(Array)
      tool_result = content.find { |item| item['type'] == 'tool_result' }
      if tool_result
        tool_summary = extract_tool_result_text(tool_result)
        return base_event.merge(
          'hook_event_type' => 'PostToolUse',
          'payload' => {
            'tool_use_id' => tool_result['tool_use_id'],
            'tool_result' => tool_summary
          },
          'summary' => 'Tool result received'
        )
      end
    end

    user_text = extract_text_content(content)
    base_event.merge(
      'hook_event_type' => 'UserPromptSubmit',
      'payload' => { 'prompt' => user_text[0, 500] },
      'summary' => user_text[0, 100]
    )
  end

  def build_assistant_event(entry, base_event)
    content = entry.dig('message', 'content')
    return nil unless content.is_a?(Array)

    tool_use = content.find { |item| item['type'] == 'tool_use' }
    if tool_use
      return base_event.merge(
        'hook_event_type' => 'PreToolUse',
        'payload' => {
          'tool_name' => tool_use['name'],
          'tool_input' => tool_use['input']
        },
        'summary' => "#{tool_use['name']}: #{tool_use['input'].to_json[0, 100]}"
      )
    end

    text_item = content.find { |item| item['type'] == 'text' }
    return nil unless text_item

    response_text = text_item['text'].to_s
    base_event.merge(
      'hook_event_type' => 'Stop',
      'payload' => { 'response' => response_text[0, 500] },
      'summary' => response_text[0, 100]
    )
  end

  def extract_text_content(content)
    return content.to_s if content.is_a?(String)

    return '' unless content.is_a?(Array)

    content
      .select { |item| item['type'] == 'text' }
      .map { |item| item['text'].to_s }
      .join(' ')
  end

  def extract_tool_result_text(tool_result)
    result = tool_result['content']
    return result.to_s if result.is_a?(String)

    return result.to_json unless result.is_a?(Array)

    result
      .select { |item| item['type'] == 'text' }
      .map { |item| item['text'].to_s }
      .join("\n")[0, 500]
  end

  def parse_timestamp_ms(value)
    return value if value.is_a?(Numeric)

    (Time.parse(value.to_s).to_f * 1000).to_i
  rescue ArgumentError, TypeError
    (Time.now.to_f * 1000).to_i
  end

  def next_id
    current = @next_id
    @next_id += 1
    current
  end

  def trim_events
    if @events.size > MAX_EVENTS
      @events = @events.last(MAX_EVENTS)
    end
  end
end
