# frozen_string_literal: true

class EventsController < ApplicationController
  include ActionController::Live

  def index
    load_events
    respond_to do |format|
      format.html
      format.json { render json: @events.map { |event| event_as_json(event) } }
    end
  end

  def list
    load_events
    render partial: 'events/list', locals: { events: @events }
  end

  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'

    last_marker = nil
    loop do
      events = current_events
      marker = events.first&.id || events.first&.timestamp
      if marker && marker != last_marker
        payload = { updated_at: Time.now.to_i, count: events.size }
        response.stream.write("event: update\n")
        response.stream.write("data: #{payload.to_json}\n\n")
        last_marker = marker
      end
      sleep 2
    end
  rescue IOError, Errno::EPIPE
    # Client disconnected.
  ensure
    response.stream.close
  end

  private

  def load_events
    store = ProjectEventStore.instance
    if store.enabled?
      store.refresh!
      @events = store.events
      @source_label = store.source_label
      @max_events = store.max_events
    else
      @events_path = events_path
      @events = Event.load_from_jsonl(@events_path)
      @source_label = @events_path
      @max_events = nil
    end
    @all_events = @events
    @filters = build_filters(@all_events)
    @events = apply_filters(@all_events)
  end

  def current_events
    store = ProjectEventStore.instance
    if store.enabled?
      store.refresh!
      store.events
    else
      Event.load_from_jsonl(events_path)
    end
  end

  def events_path
    ENV.fetch(
      'SIGNALSHELF_EVENTS_PATH',
      File.expand_path('~/.agent-kit/MEMORY/STATE/observability-events.jsonl')
    )
  end

  def apply_filters(events)
    scoped = events.dup

    if params[:hook_event_type].present?
      scoped.select! { |event| event.hook_event_type == params[:hook_event_type] }
    end

    if params[:source_app].present?
      scoped.select! { |event| event.source_app == params[:source_app] }
    end

    if params[:session_id].present?
      scoped.select! { |event| event.session_id == params[:session_id] }
    end

    if params[:since].present?
      minutes = params[:since].to_i
      if minutes.positive?
        cutoff = Time.now.to_i - (minutes * 60)
        scoped.select! { |event| event.timestamp && event.timestamp >= cutoff }
      end
    end

    if params[:q].present?
      needle = params[:q].to_s.downcase
      scoped.select! do |event|
        haystack = [
          event.summary,
          event.agent_name,
          event.hook_event_type,
          event.source_app,
          event.session_id,
          event.payload.to_json
        ].compact.join(' ').downcase
        haystack.include?(needle)
      end
    end

    scoped
  end

  def build_filters(events)
    {
      hook_event_types: events.map(&:hook_event_type).reject(&:empty?).uniq.sort,
      source_apps: events.map(&:source_app).reject(&:empty?).uniq.sort,
      session_ids: events.map(&:session_id).reject(&:empty?).uniq.sort
    }
  end

  def event_as_json(event)
    {
      id: event.id,
      hook_event_type: event.hook_event_type,
      summary: event.summary,
      source_app: event.source_app,
      session_id: event.session_id,
      agent_name: event.agent_name,
      timestamp: event.timestamp
    }
  end
end
