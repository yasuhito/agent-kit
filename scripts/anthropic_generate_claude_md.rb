#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'optparse'
require 'time'
require 'yaml'

ROOT = File.expand_path('..', __dir__)
DATA_DIR = File.join(ROOT, 'data', 'anthropic')
STATE_FILE = File.join(DATA_DIR, 'state.json')
GENERATED_DIR = File.join(DATA_DIR, 'generated')
OUTPUT_PATH = File.join(GENERATED_DIR, 'claude-md.en.md')
SOURCE_ID = 'claude-code-best-practices'

options = {
  output: OUTPUT_PATH,
  dry_run: false
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"
  opts.on('--output PATH', 'Output path') { |path| options[:output] = path }
  opts.on('--dry-run', 'Do not write files') { options[:dry_run] = true }
end.parse!

unless File.exist?(STATE_FILE)
  warn "Missing state file: #{STATE_FILE}"
  exit 1
end

state = JSON.parse(File.read(STATE_FILE))
entry = state.dig('sources', SOURCE_ID)
if entry.nil?
  warn "Missing source entry: #{SOURCE_ID}"
  exit 1
end

normalized_rel = entry['last_normalized_path']
if normalized_rel.nil? || normalized_rel.to_s.strip.empty?
  warn "Missing normalized path for #{SOURCE_ID}"
  exit 1
end

normalized_path = File.join(ROOT, normalized_rel)
unless File.exist?(normalized_path)
  warn "Normalized file not found: #{normalized_path}"
  exit 1
end

lines = File.read(normalized_path).split("\n", -1)

# Extract section starting at a heading until next heading of same or higher level.
def toggle_fence(line, current)
  if current
    return nil if line.start_with?(current)
    return current
  end

  return '```' if line.start_with?('```')
  return '~~~' if line.start_with?('~~~')

  nil
end

def extract_section(lines, heading)
  start_index = lines.index { |line| line.strip == heading }
  return nil if start_index.nil?

  start_level = heading.split.first.length
  section = [lines[start_index]]
  fence = nil

  i = start_index + 1
  while i < lines.length
    line = lines[i]
    fence = toggle_fence(line, fence)
    if fence.nil? && line.start_with?('#')
      level = line[/^#+/].length
      break if level <= start_level
    end
    section << line
    i += 1
  end

  section
end

# Extract the list item that mentions CLAUDE.md in failure patterns.
def extract_failure_block(lines, phrase)
  start_index = lines.index { |line| line.include?(phrase) }
  return nil if start_index.nil?

  block = [lines[start_index]]
  i = start_index + 1
  while i < lines.length
    line = lines[i]
    break if line.match?(/^[-*] \\*\\*/)
    break if line.strip.empty?
    block << line
    i += 1
  end

  block
end

# Convert <Tip> / <Warning> blocks into blockquotes.
def convert_mdx_blocks(lines)
  output = []
  mode = nil

  lines.each do |line|
    stripped = line.strip
    if stripped == '<Tip>'
      mode = 'Tip'
      output << '> Tip:'
      next
    end
    if stripped == '</Tip>'
      mode = nil
      output << ''
      next
    end
    if stripped == '<Warning>'
      mode = 'Warning'
      output << '> Warning:'
      next
    end
    if stripped == '</Warning>'
      mode = nil
      output << ''
      next
    end

    if mode
      output << "> #{stripped}"
    else
      output << line
    end
  end

  output
end

section = extract_section(lines, '### Write an effective CLAUDE.md')
if section.nil?
  warn 'Section not found: Write an effective CLAUDE.md'
  exit 1
end

failure_block = extract_failure_block(lines, 'over-specified CLAUDE.md')

content = []
content << '# CLAUDE.md Best Practices'
content << ''
content << "Source: #{entry['url']}"
content << "Snapshot: #{entry['last_sha256']}"
content << "Last fetched: #{entry['last_changed_at']}"
content << ''
content << '## Write an effective CLAUDE.md'
content << ''
content.concat(convert_mdx_blocks(section[1..]))
content << ''

if failure_block
  content << '## Common failure pattern: over-specified CLAUDE.md'
  content << ''
  content.concat(failure_block)
  content << ''
end

output_text = content.join("\n").gsub(/\n{3,}/, "\n\n") + "\n"

unless options[:dry_run]
  FileUtils.mkdir_p(File.dirname(options[:output]))
  File.write(options[:output], output_text)
end

puts "Wrote #{options[:output]}"
