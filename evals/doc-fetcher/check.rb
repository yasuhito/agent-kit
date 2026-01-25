#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

EVAL_DIR = File.expand_path(__dir__)
PROMPTS_FILE = File.join(EVAL_DIR, 'prompts.tsv')
RUNS_DIR = File.join(EVAL_DIR, 'runs')

unless File.exist?(PROMPTS_FILE)
  warn "Missing prompts file: #{PROMPTS_FILE}"
  exit 1
end

lines = File.readlines(PROMPTS_FILE, chomp: true)
header = lines.shift
if header != "id\tprompt\tshould_trigger"
  warn 'Unexpected prompts.tsv header'
end

path_re = %r{(skills/doc-fetcher/scripts/anthropic_fetch\.rb|scripts/anthropic_fetch\.rb)}
list_cmd_re = %r{#{path_re}.*\s--list(?:\s|$|'|\")}i

failures = []
warnings = []

def truthy?(value)
  value.to_s.strip == '1' || value.to_s.strip.downcase == 'true'
end

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

lines.each do |line|
  next if line.strip.empty?

  id, _prompt, should_trigger = line.split("\t", 3)
  run_path = File.join(RUNS_DIR, "#{id}.jsonl")

  unless File.exist?(run_path)
    failures << "#{id}: missing run file #{run_path}"
    next
  end

  commands = extract_commands(run_path)
  list_cmds = commands.select { |cmd| cmd.match?(list_cmd_re) }

  if truthy?(should_trigger)
    if list_cmds.empty?
      failures << "#{id}: expected --list command but none found"
      next
    end

    if list_cmds.any? { |cmd| cmd.match?(/--all|--id/i) }
      failures << "#{id}: --list command includes --all or --id"
    end

    if list_cmds.size > 1
      warnings << "#{id}: multiple --list commands found"
    end
  else
    failures << "#{id}: unexpected --list command found" unless list_cmds.empty?
  end
end

puts "Checked #{lines.count} cases"
if warnings.any?
  puts "Warnings:"
  warnings.each { |w| puts "- #{w}" }
end

if failures.any?
  puts "Failures:"
  failures.each { |f| puts "- #{f}" }
  exit 1
end

puts 'All checks passed'
