# frozen_string_literal: true

Given(/^Codex セッションに Task の結果がある:?$/) do |doc_string|
  @tmp_root = Dir.mktmpdir('signalshelf')
  @sessions_dir = File.join(@tmp_root, 'sessions')
  @memory_dir = File.join(@tmp_root, 'memory')
  FileUtils.mkdir_p(@sessions_dir)
  FileUtils.mkdir_p(@memory_dir)

  lines = (doc_string || '').lines.map(&:strip).reject(&:empty?)
  raise 'session JSONL is required' if lines.empty?

  events = lines.map { |line| JSON.parse(line) }
  meta = events.find { |event| event['type'] == 'session_meta' }
  payload = meta && meta['payload'].is_a?(Hash) ? meta['payload'] : {}

  @cwd = payload['cwd'] || '/home/yasuhito/Work/agent-kit'
  @thread_id = payload['id'] || "session-#{Time.now.to_i}"

  session_dir = File.join(@sessions_dir, '2026', '01', '25')
  FileUtils.mkdir_p(session_dir)
  @session_path = File.join(session_dir, "rollout-2026-01-25T00-00-00-#{@thread_id}.jsonl")

  File.open(@session_path, 'w') do |file|
    lines.each { |line| file.puts(line) }
  end
end

When('SignalShelf notify を実行する') do
  payload = {
    'type' => 'agent-turn-complete',
    'data' => {
      'thread-id' => @thread_id,
      'cwd' => @cwd,
      'last-assistant-message' => 'fallback message'
    }
  }

  script_path = File.expand_path('../../scripts/signalshelf_notify.rb', __dir__)
  ok = system(
    {
      'CODEX_SESSIONS_DIR' => @sessions_dir,
      'SIGNALSHELF_ROOT' => @memory_dir
    },
    'ruby',
    script_path,
    JSON.generate(payload)
  )

  raise 'notify script failed' unless ok

  @memory_file = Dir.glob(File.join(@memory_dir, '**', '*.md')).max_by { |path| File.mtime(path) }
  raise 'memory file not created' unless @memory_file
end

Then('メモリに agent_type が保存される') do
  content = File.read(@memory_file)
  unless content.include?('agent_type: researcher')
    raise 'agent_type not found in memory file'
  end
end

Then('メモリに completion が保存される') do
  content = File.read(@memory_file)
  unless content.include?('agent_completion: gathered sources')
    raise 'agent_completion not found in memory file'
  end
end

Then('メモリに executor が保存される') do
  content = File.read(@memory_file)
  unless content.include?('executor: codex')
    raise 'executor not set to codex'
  end
end

Then('メモリに task_description が保存される') do
  content = File.read(@memory_file)
  unless content.include?('task_description: Collect sources')
    raise 'task_description not found in memory file'
  end
end

Then('メモリに task_subagent_type が保存される') do
  content = File.read(@memory_file)
  unless content.include?('task_subagent_type: researcher')
    raise 'task_subagent_type not found in memory file'
  end
end

Then('メモリに task_run_in_background が保存される') do
  content = File.read(@memory_file)
  unless content.include?('task_run_in_background: true')
    raise 'task_run_in_background not found in memory file'
  end
end

Then('メモリに task_call_id が保存される') do
  content = File.read(@memory_file)
  unless content.include?('task_call_id: call_task_1')
    raise 'task_call_id not found in memory file'
  end
end

After do
  FileUtils.rm_rf(@tmp_root) if @tmp_root && File.directory?(@tmp_root)
end
