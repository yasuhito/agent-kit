# frozen_string_literal: true

require 'json'
require 'time'

class Event
  attr_reader :id, :source_app, :session_id, :hook_event_type, :summary, :payload,
              :agent_name, :timestamp, :raw

  def self.load_from_jsonl(path, limit: 500)
    return [] unless path && File.exist?(path)

    events = []
    File.foreach(path) do |line|
      next if line.strip.empty?

      data = JSON.parse(line)
      events << new(data)
      break if events.size >= limit
    rescue JSON::ParserError
      next
    end

    events.sort_by { |event| event.timestamp.to_i }.reverse
  end

  def initialize(data)
    @raw = data.is_a?(Hash) ? data : {}
    @id = @raw['id']
    @source_app = @raw['source_app'].to_s
    @session_id = @raw['session_id'].to_s
    @hook_event_type = (@raw['hook_event_type'] || @raw['event_type']).to_s
    @summary = (@raw['summary'] || @raw['agent_completion']).to_s
    @agent_name = (@raw['agent_name'] || @raw['agent_type']).to_s
    @payload = @raw['payload'].is_a?(Hash) ? @raw['payload'] : {}
    @timestamp = normalize_timestamp(@raw['timestamp'])
  end

  def timestamp_label
    return '' unless timestamp

    Time.at(timestamp).strftime('%Y-%m-%d %H:%M:%S')
  end

  def type_badge_class
    case hook_event_type_key
    when 'stop'
      'badge-type-stop'
    when 'agent-turn-complete'
      'badge-type-agent-turn-complete'
    when 'error'
      'badge-type-error'
    else
      ''
    end
  end

  def to_partial_path
    'events/event'
  end

  private

  def normalize_timestamp(value)
    return nil if value.nil?

    numeric = begin
      Float(value)
    rescue ArgumentError, TypeError
      nil
    end

    return parse_time_string(value) if numeric.nil?

    numeric = numeric.to_i
    numeric > 2_000_000_000 ? numeric / 1000 : numeric
  end

  def parse_time_string(value)
    Time.parse(value.to_s).to_i
  rescue ArgumentError, TypeError
    nil
  end

  def hook_event_type_key
    hook_event_type.to_s.strip.downcase.tr('_', '-')
  end
end
