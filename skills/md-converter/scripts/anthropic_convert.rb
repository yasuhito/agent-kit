#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'optparse'
require 'time'
require 'yaml'

def find_repo_root(start_dir)
  current = File.expand_path(start_dir)
  8.times do
    return current if File.directory?(File.join(current, 'data', 'anthropic'))

    parent = File.dirname(current)
    break if parent == current

    current = parent
  end
  File.expand_path('..', __dir__)
end

ROOT = find_repo_root(__dir__)
DATA_DIR = File.join(ROOT, 'data', 'anthropic')
STATE_FILE = File.join(DATA_DIR, 'state.json')
SOURCES_FILE = File.join(DATA_DIR, 'sources.yaml')
GENERATED_DIR = File.join(DATA_DIR, 'generated')

OPTIONS = {
  all: false,
  ids: [],
  dry_run: false,
  list: false
}.freeze

options = OPTIONS.dup

OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"
  opts.on('--all', 'Convert all enabled sources') { options[:all] = true }
  opts.on('--id ID', 'Convert a single source id (repeatable)') { |id| options[:ids] << id }
  opts.on('--dry-run', 'Do not write files') { options[:dry_run] = true }
  opts.on('--list', 'List sources') { options[:list] = true }
end.parse!

def load_sources
  unless File.exist?(SOURCES_FILE)
    warn "Missing sources file: #{SOURCES_FILE}"
    exit 1
  end

  data = YAML.safe_load_file(SOURCES_FILE)
  list = data.is_a?(Hash) ? data['sources'] : data
  unless list.is_a?(Array)
    warn 'sources.yaml must contain a top-level array or a sources: array'
    exit 1
  end

  list
end

def load_state
  if File.exist?(STATE_FILE)
    JSON.parse(File.read(STATE_FILE))
  else
    { 'version' => 1, 'sources' => {} }
  end
end

def toggle_fence(line, current)
  if current
    return nil if line.start_with?(current)

    return current
  end

  return '```' if line.start_with?('```')
  return '~~~' if line.start_with?('~~~')

  nil
end

def process_mdx_tag(stripped, mode)
  case stripped
  when '<Tip>' then { mode: 'Tip', output: '> **Tip:**' }
  when '<Warning>' then { mode: 'Warning', output: '> **Warning:**' }
  when '<Info>' then { mode: 'Info', output: '> **Info:**' }
  when '</Tip>', '</Warning>', '</Info>' then { mode: nil, output: '' }
  when /<section\s+title="([^"]+)">/ then { mode: mode, output: "**#{Regexp.last_match(1)}**" }
  when '</section>' then { mode: mode, output: '' }
  else { mode: mode, output: nil }
  end
end

def convert_mdx_blocks(lines)
  output = []
  mode = nil
  fence = nil

  lines.each do |line|
    fence = toggle_fence(line, fence)

    if fence
      output << line
      next
    end

    stripped = line.strip
    result = process_mdx_tag(stripped, mode)
    mode = result[:mode]

    if result[:output]
      output << result[:output] unless result[:output].empty?
      next
    end

    output << (mode ? "> #{stripped}" : line)
  end

  output
end

def build_header(entry)
  [
    "Source: #{entry['url']}",
    "Snapshot: #{entry['last_sha256']}",
    "Last fetched: #{entry['last_changed_at']}",
    ''
  ]
end

def output_filename(id)
  "#{id}.en.md"
end

sources = load_sources
state = load_state
state['sources'] ||= {}

if options[:list]
  sources.each do |source|
    next if source['enabled'] == false

    id = source['id']
    entry = state['sources'][id] || {}
    puts "#{id}\t#{entry['last_normalized_path'] || '(no normalized)'}"
  end
  exit 0
end

if !options[:all] && options[:ids].empty?
  warn 'Specify --all or --id'
  exit 1
end

selected = if options[:all]
             sources.reject { |s| s['enabled'] == false }
           else
             sources.select { |s| options[:ids].include?(s['id']) }
           end

if selected.empty?
  warn 'No sources selected'
  exit 1
end

def resolve_normalized_path(entry)
  normalized_rel = entry['last_normalized_path']
  return nil if normalized_rel.nil? || normalized_rel.to_s.strip.empty?

  normalized_path = File.join(ROOT, normalized_rel)
  return nil unless File.exist?(normalized_path)

  normalized_path
end

def convert_source(id, entry, dry_run)
  normalized_path = resolve_normalized_path(entry)
  return warn("#{id}: missing or invalid normalized path") if normalized_path.nil?

  lines = File.read(normalized_path).split("\n", -1)
  converted = convert_mdx_blocks(lines)

  content = build_header(entry)
  content.concat(converted)

  output_text = "#{content.join("\n").gsub(/\n{3,}/, "\n\n")}\n"
  output_path = File.join(GENERATED_DIR, output_filename(id))

  unless dry_run
    FileUtils.mkdir_p(GENERATED_DIR)
    File.write(output_path, output_text)
  end

  puts "#{id}: wrote #{output_path}"
end

selected.each do |source|
  id = source['id']
  entry = state['sources'][id]

  if entry.nil?
    warn "#{id}: no state entry"
    next
  end

  convert_source(id, entry, options[:dry_run])
end
