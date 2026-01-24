#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'net/http'
require 'open3'
require 'optparse'
require 'openssl'
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
DEFAULT_INPUT = File.join(ROOT, 'data', 'anthropic', 'generated', 'claude-md.en.md')
DEFAULT_OUTPUT = File.join(ROOT, 'docs', 'best-practices', 'claude-md.md')
DEFAULT_META = File.join(ROOT, 'data', 'anthropic', 'generated', 'claude-md.ja.json')

options = {
  input: DEFAULT_INPUT,
  output: DEFAULT_OUTPUT,
  meta: DEFAULT_META,
  model: 'gpt-5',
  dry_run: false,
  use_1password: false,
  op_item: 'op://Personal/OpenAI API Key/credential',
  temperature: nil,
  insecure: false,
  open_timeout: 30,
  read_timeout: 600
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"
  opts.on('--input PATH', 'Input markdown path (English)') { |path| options[:input] = path }
  opts.on('--output PATH', 'Output markdown path (Japanese)') { |path| options[:output] = path }
  opts.on('--meta PATH', 'Metadata output path') { |path| options[:meta] = path }
  opts.on('--model MODEL', 'OpenAI model (default: gpt-5)') { |model| options[:model] = model }
  opts.on('--temperature N', Float, 'Sampling temperature (if supported)') { |temp| options[:temperature] = temp }
  opts.on('--dry-run', 'Do not write files') { options[:dry_run] = true }
  opts.on('--use-1password', 'Read OPENAI_API_KEY via 1Password CLI (op)') { options[:use_1password] = true }
  opts.on('--op-item ITEM', '1Password item path for OPENAI_API_KEY') { |item| options[:op_item] = item }
  opts.on('--insecure', 'Skip SSL certificate verification') { options[:insecure] = true }
  opts.on('--open-timeout SECONDS', Integer, 'HTTP open timeout (default: 30)') { |sec| options[:open_timeout] = sec }
  opts.on('--read-timeout SECONDS', Integer, 'HTTP read timeout (default: 600)') { |sec| options[:read_timeout] = sec }
end.parse!

api_key = ENV.fetch('OPENAI_API_KEY', nil)
if (api_key.nil? || api_key.strip.empty?) && options[:use_1password]
  unless ENV['TMUX']
    warn 'Refusing to call op outside tmux. Start a tmux session and retry.'
    exit 1
  end

  op_out, op_err, op_status = Open3.capture3('op', 'read', options[:op_item])
  unless op_status.success?
    warn 'op read failed'
    warn op_err
    exit 1
  end
  api_key = op_out.strip
end

if api_key.nil? || api_key.strip.empty?
  warn 'OPENAI_API_KEY is not set'
  exit 1
end

unless File.exist?(options[:input])
  warn "Input file not found: #{options[:input]}"
  exit 1
end

def close_fence_block(buffer, blocks, output)
  placeholder = "@@CODE_BLOCK_#{blocks.length + 1}@@\n"
  blocks << buffer.join
  output << placeholder
end

def process_fence_line(line, state)
  state[:buffer] << line
  return unless line.start_with?(state[:fence])

  close_fence_block(state[:buffer], state[:blocks], state[:output])
  state[:buffer] = []
  state[:in_fence] = false
  state[:fence] = nil
end

def mask_code_blocks(text)
  state = { blocks: [], output: [], in_fence: false, fence: nil, buffer: [] }

  text.lines.each do |line|
    if state[:in_fence]
      process_fence_line(line, state)
    elsif line.start_with?('```', '~~~')
      state[:in_fence] = true
      state[:fence] = line.start_with?('```') ? '```' : '~~~'
      state[:buffer] << line
    else
      state[:output] << line
    end
  end

  state[:output].concat(state[:buffer]) if state[:in_fence]
  [state[:output].join, state[:blocks]]
end

def mask_inline_code(text, inline_map)
  text.gsub(/`[^`]+`/) do |match|
    key = "@@INLINE_CODE_#{inline_map.length + 1}@@"
    inline_map[key] = match
    key
  end
end

def unmask(text, blocks, inline_map)
  blocks.each_with_index do |block, idx|
    text = text.gsub("@@CODE_BLOCK_#{idx + 1}@@", block)
  end
  inline_map.each do |key, value|
    text = text.gsub(key, value)
  end
  text
end

def extract_output_text(response)
  return response['output_text'] if response['output_text'].is_a?(String)

  outputs = response['output']
  return nil unless outputs.is_a?(Array)

  outputs.each do |item|
    next unless item['type'] == 'message'

    content = item['content']
    next unless content.is_a?(Array)

    content.each do |part|
      return part['text'] if part['type'] == 'output_text' && part['text']
    end
  end

  nil
end

input_text = File.read(options[:input])
masked_text, blocks = mask_code_blocks(input_text)
inline_map = {}
masked_text = mask_inline_code(masked_text, inline_map)

instructions = <<~INSTRUCTIONS
  You are a translation engine.
  Translate the input Markdown into Japanese.
  Rules:
  - Preserve Markdown structure exactly (headings, lists, tables, blockquotes).
  - Do not translate placeholders like @@CODE_BLOCK_1@@ or @@INLINE_CODE_1@@.
  - Do not add commentary or explanations.
  - Keep URLs unchanged.
  Return only the translated Markdown.
INSTRUCTIONS

uri = URI('https://api.openai.com/v1/responses')
req = Net::HTTP::Post.new(uri)
req['Authorization'] = "Bearer #{api_key}"
req['Content-Type'] = 'application/json'
payload = {
  model: options[:model],
  instructions: instructions,
  input: masked_text
}
payload[:temperature] = options[:temperature] unless options[:temperature].nil?

req.body = JSON.generate(payload)

http = Net::HTTP.new(uri.hostname, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE if options[:insecure]
http.open_timeout = options[:open_timeout]
http.read_timeout = options[:read_timeout]
res = http.request(req)

unless res.is_a?(Net::HTTPSuccess)
  warn "OpenAI API error: HTTP #{res.code}"
  warn res.body
  exit 1
end

response_json = JSON.parse(res.body)
translated = extract_output_text(response_json)
if translated.nil? || translated.strip.empty?
  warn 'No output_text found in response'
  exit 1
end

translated = unmask(translated, blocks, inline_map)
translated = "#{translated.gsub(/\n{3,}/, "\n\n")}\n"

unless options[:dry_run]
  FileUtils.mkdir_p(File.dirname(options[:output]))
  File.write(options[:output], translated)

  meta = {
    'source' => options[:input],
    'output' => options[:output],
    'model' => options[:model],
    'generated_at' => Time.now.utc.iso8601
  }
  FileUtils.mkdir_p(File.dirname(options[:meta]))
  File.write(options[:meta], "#{JSON.pretty_generate(meta)}\n")
end

puts "Wrote #{options[:output]}"
