#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'json'
require 'net/http'
require 'optparse'
require 'time'
require 'uri'
require 'yaml'

ROOT = File.expand_path('..', __dir__)
DATA_DIR = File.join(ROOT, 'data', 'anthropic')
SOURCES_FILE = File.join(DATA_DIR, 'sources.yaml')
STATE_FILE = File.join(DATA_DIR, 'state.json')
SNAPSHOT_DIR = File.join(DATA_DIR, 'snapshots')
USER_AGENT = 'agent-kit-anthropic-fetcher/0.1'

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
  opts.on('--all', 'Fetch all enabled sources') { options[:all] = true }
  opts.on('--id ID', 'Fetch a single source id (repeatable)') { |id| options[:ids] << id }
  opts.on('--force', 'Skip conditional headers and always download') { options[:force] = true }
  opts.on('--dry-run', 'Do not write files') { options[:dry_run] = true }
  opts.on('--list', 'List sources') { options[:list] = true }
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
  %w[url etag last_modified last_status last_checked_at last_changed_at last_sha256 last_snapshot_path last_bytes last_content_type].each do |key|
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

def slug_dir(id)
  id.to_s.strip.empty? ? 'unknown' : id.to_s
end

def build_request(uri, state_entry, force)
  req = Net::HTTP::Get.new(uri.request_uri)
  req['User-Agent'] = USER_AGENT
  req['Accept'] = 'text/html,application/xhtml+xml'
  unless force
    req['If-None-Match'] = state_entry['etag'] if state_entry['etag']
    req['If-Modified-Since'] = state_entry['last_modified'] if state_entry['last_modified']
  end
  req
end

def snapshot_extension(content_type)
  return 'md' if content_type&.include?('text/markdown')
  'html'
end

def write_snapshot(id, url, response, body, dry_run)
  sha256 = Digest::SHA256.hexdigest(body)
  dir = File.join(SNAPSHOT_DIR, slug_dir(id))
  content_type = response['content-type'].to_s
  ext = snapshot_extension(content_type)
  snapshot_path = File.join(dir, "#{sha256}.#{ext}")
  meta_path = File.join(dir, "#{sha256}.json")

  meta = {
    'id' => id,
    'url' => url,
    'fetched_at' => Time.now.utc.iso8601,
    'status' => response.code.to_i,
    'content_type' => content_type,
    'etag' => response['etag'],
    'last_modified' => response['last-modified'],
    'sha256' => sha256,
    'bytes' => body.bytesize
  }

  unless dry_run
    FileUtils.mkdir_p(dir)
    File.write(snapshot_path, body) unless File.exist?(snapshot_path)
    File.write(meta_path, JSON.pretty_generate(meta) + "\n") unless File.exist?(meta_path)
  end

  {
    sha256: sha256,
    bytes: body.bytesize,
    snapshot_path: snapshot_path,
    changed_at: meta['fetched_at']
  }
end

sources = load_sources

if options[:list]
  sources.each do |source|
    next if source['enabled'] == false
    puts "#{source['id']}\t#{source['url']}"
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

state = load_state
state['sources'] ||= {}

selected.each do |source|
  id = source['id']
  url = source['url']
  if id.to_s.strip.empty? || url.to_s.strip.empty?
    warn 'Each source must include id and url'
    next
  end

  uri = URI(url)
  state_entry = state['sources'][id] || { 'url' => url }

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  http.read_timeout = 20
  http.open_timeout = 10

  request = build_request(uri, state_entry, options[:force])
  response = http.request(request)

  now = Time.now.utc.iso8601
  state_entry['url'] = url
  state_entry['last_status'] = response.code.to_i
  state_entry['last_checked_at'] = now

  if response.code.to_i == 304
    state['sources'][id] = state_entry
    puts "#{id}: not modified"
    next
  end

  if response.code.to_i >= 200 && response.code.to_i < 300
    body = response.body || ''
    snapshot = write_snapshot(id, url, response, body, options[:dry_run])

    if state_entry['last_sha256'] == snapshot[:sha256]
      puts "#{id}: unchanged content"
    else
      puts "#{id}: updated (#{snapshot[:sha256]})"
      state_entry['last_changed_at'] = snapshot[:changed_at]
    end

    state_entry['etag'] = response['etag'] if response['etag']
    state_entry['last_modified'] = response['last-modified'] if response['last-modified']
    state_entry['last_sha256'] = snapshot[:sha256]
    state_entry['last_snapshot_path'] = snapshot[:snapshot_path].sub(ROOT + '/', '')
    state_entry['last_bytes'] = snapshot[:bytes]
    state_entry['last_content_type'] = response['content-type'] if response['content-type']
  else
    warn "#{id}: HTTP #{response.code}"
  end

  state['sources'][id] = state_entry
end

save_state(state, options[:dry_run])
