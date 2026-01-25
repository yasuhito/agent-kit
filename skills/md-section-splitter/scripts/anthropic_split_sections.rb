#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'optparse'
require 'time'

def find_repo_root(start_dir)
  current = File.expand_path(start_dir)
  8.times do
    return current if File.directory?(File.join(current, 'skills'))

    parent = File.dirname(current)
    break if parent == current

    current = parent
  end
  File.expand_path('..', __dir__)
end

ROOT = find_repo_root(__dir__)
DATA_DIR = File.join(ROOT, 'data', 'doc-fetcher')
STATE_FILE = File.join(DATA_DIR, 'state.json')
SECTIONS_DIR = File.join(DATA_DIR, 'sections')

def usage
  basename = File.basename($PROGRAM_NAME)
  <<~USAGE
    Usage:
      #{basename} list
      #{basename} split --all|--id ID [--id ID ...] [--force] [--dry-run]

    Commands:
      list  Show sources and last normalized path from state.json
      split Split normalized Markdown into sections

    Examples:
      #{basename} list
      #{basename} split --all
      #{basename} split --id best-practices
  USAGE
end

subcommand = ARGV.shift
if subcommand.nil? || %w[-h --help].include?(subcommand)
  puts usage
  exit 0
end

unless %w[list split].include?(subcommand)
  warn usage
  exit 1
end

options = {
  all: false,
  ids: [],
  force: false,
  dry_run: false
}

case subcommand
when 'list'
  OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} list"
    opts.on('-h', '--help', 'Show this help') do
      puts opts
      exit 0
    end
  end.parse!
when 'split'
  OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} split [options]"
    opts.on('--all', 'Split all sources in state.json') { options[:all] = true }
    opts.on('--id ID', 'Split a single source id (repeatable)') { |id| options[:ids] << id }
    opts.on('--force', 'Overwrite existing section output') { options[:force] = true }
    opts.on('--dry-run', 'Do not write files') { options[:dry_run] = true }
    opts.on('-h', '--help', 'Show this help') do
      puts opts
      exit 0
    end
  end.parse!
end

def load_state
  if File.exist?(STATE_FILE)
    JSON.parse(File.read(STATE_FILE))
  else
    { 'version' => 1, 'sources' => {} }
  end
end

def normalize_entry(entry)
  ordered = {}
  %w[url etag last_modified last_status last_checked_at last_changed_at last_sha256 last_snapshot_path last_bytes
     last_normalized_sha256 last_normalized_path last_normalized_at last_sections_path last_sections_at].each do |key|
    ordered[key] = entry[key] if entry.key?(key)
  end
  entry.each do |key, value|
    ordered[key] = value unless ordered.key?(key)
  end
  ordered
end

def normalize_state(state)
  sources = state['sources'] || {}
  ordered_sources = {}
  sources.keys.sort.each do |key|
    ordered_sources[key] = normalize_entry(sources[key])
  end
  state['sources'] = ordered_sources
  state
end

def save_state(state, dry_run)
  return if dry_run

  FileUtils.mkdir_p(File.dirname(STATE_FILE))
  tmp = "#{STATE_FILE}.tmp"
  File.write(tmp, "#{JSON.pretty_generate(normalize_state(state))}\n")
  FileUtils.mv(tmp, STATE_FILE)
end

def slugify(text)
  slug = text.downcase
  slug = slug.encode('ASCII', invalid: :replace, undef: :replace, replace: '')
  slug = slug.gsub(/[^a-z0-9]+/, '-')
  slug = slug.gsub(/^-+|-+$/, '')
  slug = 'section' if slug.empty?
  slug
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

def split_sections(lines)
  preamble = []
  sections = []
  current = nil
  fence = nil

  lines.each do |line|
    fence = toggle_fence(line, fence)

    if fence.nil? && line.start_with?('## ')
      sections << current if current
      current = { 'heading' => line.sub(/^##\s+/, '').strip, 'lines' => [line] }
      next
    end

    if current
      current['lines'] << line
    else
      preamble << line
    end
  end

  sections << current if current
  [preamble, sections]
end

state = load_state
state['sources'] ||= {}
sources = state['sources']

if subcommand == 'list'
  sources.keys.sort.each do |id|
    entry = sources[id] || {}
    puts "#{id}\t#{entry['last_normalized_path'] || '(no normalized)'}"
  end
  exit 0
end

if !options[:all] && options[:ids].empty?
  warn 'Specify --all or --id'
  exit 1
end

selected_ids = if options[:all]
                 sources.keys.sort
               else
                 options[:ids]
               end

if selected_ids.empty?
  warn 'No sources selected'
  exit 1
end

def resolve_normalized_path(state_entry)
  normalized_rel = state_entry['last_normalized_path']
  return nil if normalized_rel.nil? || normalized_rel.to_s.strip.empty?

  normalized_path = File.join(ROOT, normalized_rel)
  return nil unless File.exist?(normalized_path)

  { rel: normalized_rel, path: normalized_path }
end

def write_section_files(output_dir, preamble, sections, width)
  FileUtils.rm_rf(output_dir)
  FileUtils.mkdir_p(output_dir)

  File.write(File.join(output_dir, 'index.md'), "#{preamble.join("\n")}\n")

  sections.each_with_index do |section, idx|
    slug = slugify(section['heading'])
    prefix = (idx + 1).to_s.rjust(width, '0')
    path = File.join(output_dir, "#{prefix}-#{slug}.md")
    File.write(path, "#{section['lines'].join("\n")}\n")
  end
end

def build_sections_meta(context, sections, width)
  {
    'id' => context[:id],
    'url' => context[:url],
    'normalized_path' => context[:normalized_rel],
    'snapshot_sha256' => context[:snapshot_sha],
    'sections' => sections.map.with_index do |section, idx|
      prefix = (idx + 1).to_s.rjust(width, '0')
      { 'index' => idx + 1, 'heading' => section['heading'], 'file' => "#{prefix}-#{slugify(section['heading'])}.md" }
    end,
    'generated_at' => context[:timestamp]
  }
end

def write_sections_output(output_dir, preamble, sections, width, context)
  write_section_files(output_dir, preamble, sections, width)
  meta = build_sections_meta(context, sections, width)
  File.write(File.join(output_dir, 'index.json'), "#{JSON.pretty_generate(meta)}\n")
end

def update_state_entry(state_entry, url, output_dir, timestamp)
  state_entry['url'] = url
  state_entry['last_sections_path'] = output_dir.sub("#{ROOT}/", '')
  state_entry['last_sections_at'] = timestamp
end

def split_and_write(normalized, id, url, dry_run)
  snapshot_sha = File.basename(normalized[:path], '.md')
  output_dir = File.join(SECTIONS_DIR, id, snapshot_sha)

  lines = File.read(normalized[:path]).split("\n", -1)
  preamble, sections = split_sections(lines)
  width = [sections.length, 1].max.to_s.length
  timestamp = Time.now.utc.iso8601

  unless dry_run
    context = { id: id, url: url, normalized_rel: normalized[:rel], snapshot_sha: snapshot_sha, timestamp: timestamp }
    write_sections_output(output_dir, preamble, sections, width, context)
  end

  { output_dir: output_dir, timestamp: timestamp }
end

def process_source(id, state, force, dry_run)
  state_entry = state['sources'][id]
  return warn("#{id}: unknown source id") if state_entry.nil?

  url = state_entry['url']

  normalized = resolve_normalized_path(state_entry)
  return warn("#{id}: normalized markdown missing or not found") if normalized.nil?

  output_dir = File.join(SECTIONS_DIR, id, File.basename(normalized[:path], '.md'))
  return puts("#{id}: sections exist") if File.exist?(output_dir) && !force

  result = split_and_write(normalized, id, url, dry_run)
  update_state_entry(state_entry, url, result[:output_dir], result[:timestamp])
  state['sources'][id] = state_entry
  puts "#{id}: sections split"
end

selected_ids.each { |id| process_source(id, state, options[:force], options[:dry_run]) }

save_state(state, options[:dry_run])
