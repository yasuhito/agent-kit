#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'json'
require 'open3'
require 'optparse'
require 'time'

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
NORMALIZED_DIR = File.join(DATA_DIR, 'normalized')

PANDOC_ARGS_HTML = [
  '--from=html',
  '--to=gfm',
  '--wrap=none',
  '--markdown-headings=atx'
].freeze

PANDOC_ARGS_MARKDOWN = [
  '--from=markdown',
  '--to=gfm',
  '--wrap=none',
  '--markdown-headings=atx'
].freeze

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
  opts.on('--all', 'Normalize all sources in state.json') { options[:all] = true }
  opts.on('--id ID', 'Normalize a single source id (repeatable)') { |id| options[:ids] << id }
  opts.on('--force', 'Overwrite existing normalized output') { options[:force] = true }
  opts.on('--dry-run', 'Do not write files') { options[:dry_run] = true }
  opts.on('--list', 'List sources and last snapshot path') { options[:list] = true }
end.parse!

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
     last_content_type last_normalized_sha256 last_normalized_path last_normalized_at].each do |key|
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

def pandoc_version
  stdout, _stderr, status = Open3.capture3('pandoc', '--version')
  unless status.success?
    warn 'pandoc not available'
    exit 1
  end
  stdout.lines.first&.strip
end

def run_pandoc(args, input)
  Open3.capture3('pandoc', *args, stdin_data: input)
end

def ensure_snapshot_path(state_entry)
  path = state_entry['last_snapshot_path']
  return nil if path.nil? || path.to_s.strip.empty?

  File.join(ROOT, path)
end

def write_normalized(context, markdown, dry_run)
  normalized_sha = Digest::SHA256.hexdigest(markdown)
  dir = File.join(NORMALIZED_DIR, context[:id])
  md_path = File.join(dir, "#{context[:snapshot_sha]}.md")
  meta_path = File.join(dir, "#{context[:snapshot_sha]}.json")

  meta = {
    'id' => context[:id],
    'url' => context[:url],
    'snapshot_path' => context[:snapshot_path].sub("#{ROOT}/", ''),
    'snapshot_sha256' => context[:snapshot_sha],
    'normalized_sha256' => normalized_sha,
    'pandoc_version' => context[:pandoc_ver],
    'pandoc_args' => context[:pandoc_args],
    'normalized_at' => Time.now.utc.iso8601
  }

  unless dry_run
    FileUtils.mkdir_p(dir)
    File.write(md_path, markdown)
    File.write(meta_path, "#{JSON.pretty_generate(meta)}\n")
  end

  {
    normalized_sha: normalized_sha,
    normalized_path: md_path,
    normalized_at: meta['normalized_at']
  }
end

state = load_state
state['sources'] ||= {}
sources = state['sources']

if options[:list]
  sources.keys.sort.each do |id|
    entry = sources[id] || {}
    puts "#{id}\t#{entry['last_snapshot_path'] || '(no snapshot)'}"
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

def prepare_snapshot(state_entry)
  snapshot_path = ensure_snapshot_path(state_entry)
  return nil if snapshot_path.nil? || !File.exist?(snapshot_path)

  snapshot_sha = state_entry['last_sha256']
  if snapshot_sha.nil? || snapshot_sha.to_s.strip.empty?
    snapshot_sha = Digest::SHA256.hexdigest(File.read(snapshot_path))
  end

  { path: snapshot_path, sha: snapshot_sha }
end

def convert_to_markdown(snapshot_path, input)
  ext = File.extname(snapshot_path).downcase
  if ext == '.md'
    { output: input, pandoc_args: ['passthrough'], pandoc_ver: nil }
  else
    pandoc_ver = pandoc_version
    stdout, stderr, status = run_pandoc(PANDOC_ARGS_HTML, input)
    return { error: stderr } unless status.success?

    { output: stdout, pandoc_args: PANDOC_ARGS_HTML, pandoc_ver: pandoc_ver }
  end
end

def update_state_with_result(state_entry, url, result)
  state_entry['url'] = url
  state_entry['last_normalized_sha256'] = result[:normalized_sha]
  state_entry['last_normalized_path'] = result[:normalized_path].sub("#{ROOT}/", '')
  state_entry['last_normalized_at'] = result[:normalized_at]
end

def process_source(id, state, force, dry_run)
  state_entry = state['sources'][id]
  return warn("#{id}: unknown source id") if state_entry.nil?

  url = state_entry['url']

  snapshot = prepare_snapshot(state_entry)
  return warn("#{id}: snapshot missing") if snapshot.nil?

  normalized_path = File.join(NORMALIZED_DIR, id, "#{snapshot[:sha]}.md")
  return puts("#{id}: normalized exists") if File.exist?(normalized_path) && !force

  conversion = convert_to_markdown(snapshot[:path], File.read(snapshot[:path]))
  return warn("#{id}: pandoc failed\n#{conversion[:error]}") if conversion[:error]

  context = { id: id, url: url, snapshot_path: snapshot[:path], snapshot_sha: snapshot[:sha],
              pandoc_ver: conversion[:pandoc_ver], pandoc_args: conversion[:pandoc_args] }
  result = write_normalized(context, conversion[:output], dry_run)

  update_state_with_result(state_entry, url, result)
  state['sources'][id] = state_entry
  puts "#{id}: normalized"
end

selected_ids.each { |id| process_source(id, state, options[:force], options[:dry_run]) }

save_state(state, options[:dry_run])
