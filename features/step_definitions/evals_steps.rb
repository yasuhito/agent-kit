# frozen_string_literal: true

require 'json'
require 'open3'
require 'fileutils'

ROOT = File.expand_path('../..', __dir__)
EVAL_TOOL_CONFIG = {
  'doc-fetcher' => {
    runs_dir: File.join(ROOT, 'evals', 'doc-fetcher', 'runs'),
    path_re: %r{skills/doc-fetcher/scripts/doc_fetcher\.rb}
  },
  'md-normalizer' => {
    runs_dir: File.join(ROOT, 'evals', 'md-normalizer', 'runs'),
    path_re: %r{(?:skills/md-normalizer/scripts/md_normalizer\.rb|scripts/md_normalizer\.rb)}
  },
  'md-section-splitter' => {
    runs_dir: File.join(ROOT, 'evals', 'md-section-splitter', 'runs'),
    path_re: %r{(?:skills/md-section-splitter/scripts/md_section_splitter\.rb|scripts/md_section_splitter\.rb)}
  },
  'md-converter' => {
    runs_dir: File.join(ROOT, 'evals', 'md-converter', 'runs'),
    path_re: %r{(?:skills/md-converter/scripts/md_converter\.rb|scripts/md_converter\.rb)}
  }
}.freeze

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

def prepare_codex_home
  codex_home = File.join(ROOT, '.codex')
  FileUtils.mkdir_p(codex_home)

  %w[auth.json config.toml models_cache.json].each do |name|
    src = File.expand_path(File.join('~/.codex', name))
    dst = File.join(codex_home, name)
    next unless File.exist?(src)
    next if File.exist?(dst)

    FileUtils.cp(src, dst)
  end

  codex_home
end

Given(/^(doc-fetcher|md-normalizer|md-section-splitter|md-converter) eval ケース "([^"]+)" のプロンプト:$/) do |tool, id, doc_string|
  prompt = doc_string.to_s.strip
  raise 'prompt is required' if prompt.empty?

  config = EVAL_TOOL_CONFIG.fetch(tool)
  @eval_tool = tool
  @runs_dir = config[:runs_dir]
  @list_cmd_re = %r{#{config[:path_re]}\s+list(?:\s|$|'|\")}i
  @eval_id = id
  @prompt = prompt
end

When('Codex でプロンプトを実行する') do
  raise 'prompt not set' unless @prompt

  FileUtils.mkdir_p(@runs_dir)
  @run_path = File.join(@runs_dir, "#{@eval_id}.jsonl")

  codex_home = prepare_codex_home
  env = { 'CODEX_HOME' => codex_home }
  stdout, stderr, status = Open3.capture3(env, 'codex', 'exec', '--json', '--full-auto', @prompt)
  File.write(@run_path, stdout)

  @codex_status = status
  @codex_stderr = stderr
end

Then('list コマンドが有効に実行されている') do
  commands = extract_commands(@run_path)
  list_cmds = commands.select { |cmd| cmd.match?(@list_cmd_re) }

  if list_cmds.empty?
    detail = @codex_status&.success? ? '' : " (codex exit=#{@codex_status.exitstatus})"
    raise "list command not found#{detail}"
  end
end

Then('list コマンドが実行されていない') do
  commands = extract_commands(@run_path)
  list_cmds = commands.select { |cmd| cmd.match?(@list_cmd_re) }

  raise 'unexpected list command found' unless list_cmds.empty?
end
