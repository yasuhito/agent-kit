#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'json'
require 'net/http'
require 'openssl'
require 'optparse'
require 'time'
require 'uri'

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
SNAPSHOT_DIR = File.join(DATA_DIR, 'snapshots')
USER_AGENT = 'agent-kit-doc-fetcher/0.1'

def usage
  basename = File.basename($PROGRAM_NAME)
  <<~USAGE
    Usage:
      #{basename} list [--url URL ...]
      #{basename} fetch --url URL [--url URL ...] [--force] [--dry-run] [--insecure]

    Commands:
      list   Show tracked sources from state.json (or preview ids for URLs)
      fetch  Fetch URL(s) and write snapshots/state

    Examples:
      #{basename} list
      #{basename} list --url https://example.com/docs.md
      #{basename} fetch --url https://example.com/docs.md
  USAGE
end

subcommand = ARGV.shift
if subcommand.nil? || %w[-h --help].include?(subcommand)
  puts usage
  exit 0
end

unless %w[list fetch].include?(subcommand)
  warn usage
  exit 1
end

options = {
  urls: [],
  force: false,
  dry_run: false,
  insecure: false
}

case subcommand
when 'list'
  OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} list [options]"
    opts.on('--url URL', 'Print derived id for URL (repeatable)') { |url| options[:urls] << url }
    opts.on('-h', '--help', 'Show this help') do
      puts opts
      exit 0
    end
  end.parse!
when 'fetch'
  OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} fetch [options]"
    opts.on('--url URL', 'Fetch a URL directly (repeatable, id derived from URL)') { |url| options[:urls] << url }
    opts.on('--force', 'Skip conditional headers and always download') { options[:force] = true }
    opts.on('--dry-run', 'Do not write files') { options[:dry_run] = true }
    opts.on('--insecure', 'Skip SSL certificate verification') { options[:insecure] = true }
    opts.on('-h', '--help', 'Show this help') do
      puts opts
      exit 0
    end
  end.parse!
end

def parse_url(url)
  URI(url)
rescue URI::InvalidURIError
  nil
end

def default_id_for(url)
  uri = parse_url(url)
  base = if uri
           "#{uri.host}#{uri.path}"
         else
           url.to_s
         end
  base = base.gsub(/[^a-z0-9]+/i, '-').squeeze('-').gsub(/^-|-$/, '')
  base = 'source' if base.empty?
  base = "#{base}-#{Digest::SHA256.hexdigest(uri.query)[0, 8]}" if uri&.query && !uri.query.empty?
  base
end

def ensure_unique_id(id, used_ids, url)
  return id unless used_ids.include?(id)

  suffix = Digest::SHA256.hexdigest(url.to_s)[0, 8]
  candidate = "#{id}-#{suffix}"
  while used_ids.include?(candidate)
    suffix = Digest::SHA256.hexdigest("#{url}-#{candidate}")[0, 8]
    candidate = "#{id}-#{suffix}"
  end
  candidate
end

def build_sources_from_urls(urls)
  used_ids = {}
  sources = []
  urls.each do |url|
    parsed = parse_url(url)
    unless parsed
      warn "Invalid URL: #{url}"
      next
    end
    id = default_id_for(url)
    id = ensure_unique_id(id, used_ids, url)
    used_ids[id] = true
    sources << { 'id' => id, 'url' => url }
  end
  sources
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
     last_content_type].each do |key|
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
    File.write(meta_path, "#{JSON.pretty_generate(meta)}\n") unless File.exist?(meta_path)
  end

  {
    sha256: sha256,
    bytes: body.bytesize,
    snapshot_path: snapshot_path,
    changed_at: meta['fetched_at']
  }
end

if subcommand == 'list'
  if options[:urls].any?
    build_sources_from_urls(options[:urls]).each do |source|
      puts "#{source['id']}\t#{source['url']}"
    end
  else
    state = load_state
    sources = state.fetch('sources', {})
    sources.keys.sort.each do |key|
      entry = sources[key]
      url = entry.is_a?(Hash) ? entry['url'] : nil
      next unless url

      puts "#{key}\t#{url}"
    end
  end
  exit 0
end

if options[:urls].empty?
  warn 'Specify at least one --url'
  exit 1
end

selected = build_sources_from_urls(options[:urls])

if selected.empty?
  warn 'No sources selected'
  exit 1
end

state = load_state
state['sources'] ||= {}

def fetch_source(http, uri, state_entry, force)
  request = build_request(uri, state_entry, force)
  http.request(request)
end

def update_state_entry_success(state_entry, response, snapshot)
  state_entry['etag'] = response['etag'] if response['etag']
  state_entry['last_modified'] = response['last-modified'] if response['last-modified']
  state_entry['last_sha256'] = snapshot[:sha256]
  state_entry['last_snapshot_path'] = snapshot[:snapshot_path].sub("#{ROOT}/", '')
  state_entry['last_bytes'] = snapshot[:bytes]
  state_entry['last_content_type'] = response['content-type'] if response['content-type']
end

def process_response(id, url, response, state_entry, dry_run)
  return :not_modified if response.code.to_i == 304

  unless response.code.to_i.between?(200, 299)
    warn "#{id}: HTTP #{response.code}"
    return :error
  end

  body = response.body || ''
  snapshot = write_snapshot(id, url, response, body, dry_run)

  if state_entry['last_sha256'] == snapshot[:sha256]
    puts "#{id}: unchanged content"
  else
    puts "#{id}: updated (#{snapshot[:sha256]})"
    state_entry['last_changed_at'] = snapshot[:changed_at]
  end

  update_state_entry_success(state_entry, response, snapshot)
  :success
end

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
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE if options[:insecure]
  http.read_timeout = 20
  http.open_timeout = 10

  response = fetch_source(http, uri, state_entry, options[:force])

  state_entry['url'] = url
  state_entry['last_status'] = response.code.to_i
  state_entry['last_checked_at'] = Time.now.utc.iso8601

  result = process_response(id, url, response, state_entry, options[:dry_run])
  if result == :not_modified
    state['sources'][id] = state_entry
    puts "#{id}: not modified"
    next
  end

  state['sources'][id] = state_entry
end

save_state(state, options[:dry_run])
