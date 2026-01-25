# frozen_string_literal: true

require 'json'
require 'open3'
require 'fileutils'

ROOT = File.expand_path('../../..', __dir__)
RUNS_DIR = File.join(ROOT, 'evals', 'doc-fetcher', 'runs')
PATH_RE = %r{skills/doc-fetcher/scripts/doc_fetcher\.rb}
LIST_CMD_RE = %r{#{PATH_RE}\s+list(?:\s|$|'|\")}i

def extract_commands(run_path)
  commands = []
  File.foreach(run_path) do |raw|
    begin
      event = JSON.parse(raw)
    rescue JSON::ParserError
      next
    end

    item = event.is_a?(Hash) ? event['item'] : nil
    next unless item.is_a?(Hash)
    next unless item['type'] == 'command_execution'
    next unless item['status'].to_s == 'completed'

    command = item['command'].to_s
    commands << command unless command.empty?
  end
  commands
end

Given(/^doc-fetcher eval ケース "([^"]+)" のプロンプト:$/) do |id, doc_string|
  prompt = doc_string.to_s.strip
  raise 'prompt is required' if prompt.empty?

  @eval_id = id
  @prompt = prompt
end

When('Codex でプロンプトを実行する') do
  raise 'prompt not set' unless @prompt

  FileUtils.mkdir_p(RUNS_DIR)
  @run_path = File.join(RUNS_DIR, "#{@eval_id}.jsonl")

  stdout, stderr, status = Open3.capture3('codex', 'exec', '--json', '--full-auto', @prompt)
  File.write(@run_path, stdout)

  @codex_status = status
  @codex_stderr = stderr
end

Then('list コマンドが有効に実行されている') do
  commands = extract_commands(@run_path)
  list_cmds = commands.select { |cmd| cmd.match?(LIST_CMD_RE) }

  if list_cmds.empty?
    detail = @codex_status&.success? ? '' : " (codex exit=#{@codex_status.exitstatus})"
    raise "list command not found#{detail}"
  end
end

Then('list コマンドが実行されていない') do
  commands = extract_commands(@run_path)
  list_cmds = commands.select { |cmd| cmd.match?(LIST_CMD_RE) }

  raise 'unexpected list command found' unless list_cmds.empty?
end
