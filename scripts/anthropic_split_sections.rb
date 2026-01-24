#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'optparse'
require 'time'
require 'yaml'

ROOT = File.expand_path('..', __dir__)
DATA_DIR = File.join(ROOT, 'data', 'anthropic')
SOURCES_FILE = File.join(DATA_DIR, 'sources.yaml')
STATE_FILE = File.join(DATA_DIR, 'state.json')
SECTIONS_DIR = File.join(DATA_DIR, 'sections')

OPTIONS = {
  all: false,
  ids: [],
  force: false,
  dry_run: false,
  list: false
}.freeze

options = OPTIONS.dup

OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"
  opts.on('--all', 'Split all enabled sources') { options[:all] = true }
  opts.on('--id ID', 'Split a single source id (repeatable)') { |id| options[:ids] << id }
  opts.on('--force', 'Overwrite existing section output') { options[:force] = true }
  opts.on('--dry-run', 'Do not write files') { options[:dry_run] = true }
  opts.on('--list', 'List sources and last normalized path') { options[:list] = true }
end.parse!

def load_sources
  unless File.exist?(SOURCES_FILE)
    warn "Missing sources file: #{SOURCES_FILE}"
    exit 1
  end

  data = YAML.safe_load(File.read(SOURCES_FILE))
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

def normalize_entry(entry)
  ordered = {}
  %w[url etag last_modified last_status last_checked_at last_changed_at last_sha256 last_snapshot_path last_bytes last_normalized_sha256 last_normalized_path last_normalized_at last_sections_path last_sections_at].each do |key|
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
  File.write(tmp, JSON.pretty_generate(normalize_state(state)) + "\n")
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

fence = nil

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
             sources.select { |s| s['enabled'] != false }
           else
             sources.select { |s| options[:ids].include?(s['id']) }
           end

if selected.empty?
  warn 'No sources selected'
  exit 1
end

selected.each do |source|
  id = source['id']
  url = source['url']
  if id.to_s.strip.empty? || url.to_s.strip.empty?
    warn 'Each source must include id and url'
    next
  end

  state_entry = state['sources'][id] || { 'url' => url }
  normalized_rel = state_entry['last_normalized_path']
  if normalized_rel.nil? || normalized_rel.to_s.strip.empty?
    warn "#{id}: normalized markdown missing"
    next
  end

  normalized_path = File.join(ROOT, normalized_rel)
  unless File.exist?(normalized_path)
    warn "#{id}: normalized file not found"
    next
  end

  snapshot_sha = File.basename(normalized_path, '.md')
  output_dir = File.join(SECTIONS_DIR, id, snapshot_sha)

  if File.exist?(output_dir) && !options[:force]
    puts "#{id}: sections exist"
    next
  end

  lines = File.read(normalized_path).split("\n", -1)
  preamble, sections = split_sections(lines)

  width = [sections.length, 1].max.to_s.length
  timestamp = Time.now.utc.iso8601

  unless options[:dry_run]
    FileUtils.rm_rf(output_dir) if File.exist?(output_dir)
    FileUtils.mkdir_p(output_dir)

    preamble_path = File.join(output_dir, 'index.md')
    File.write(preamble_path, preamble.join("\n") + "\n")

    sections.each_with_index do |section, idx|
      slug = slugify(section['heading'])
      prefix = (idx + 1).to_s.rjust(width, '0')
      path = File.join(output_dir, "#{prefix}-#{slug}.md")
      File.write(path, section['lines'].join("\n") + "\n")
    end

    meta = {
      'id' => id,
      'url' => url,
      'normalized_path' => normalized_rel,
      'snapshot_sha256' => snapshot_sha,
      'sections' => sections.map.with_index do |section, idx|
        {
          'index' => idx + 1,
          'heading' => section['heading'],
          'file' => "#{(idx + 1).to_s.rjust(width, '0')}-#{slugify(section['heading'])}.md"
        }
      end,
      'generated_at' => timestamp
    }

    File.write(File.join(output_dir, 'index.json'), JSON.pretty_generate(meta) + "\n")
  end

  state_entry['url'] = url
  state_entry['last_sections_path'] = output_dir.sub(ROOT + '/', '')
  state_entry['last_sections_at'] = timestamp
  state['sources'][id] = state_entry

  puts "#{id}: sections split"
end

save_state(state, options[:dry_run])
