# frozen_string_literal: true

class EventsController < ApplicationController
  def index
    store = ProjectEventStore.instance
    if store.enabled?
      store.refresh!
      @events = store.events
      @source_label = store.source_label
    else
      @events_path = events_path
      @events = Event.load_from_jsonl(@events_path)
      @source_label = @events_path
    end
  end

  private

  def events_path
    ENV.fetch(
      'SIGNALSHELF_EVENTS_PATH',
      File.expand_path('~/.agent-kit/MEMORY/STATE/observability-events.jsonl')
    )
  end
end
