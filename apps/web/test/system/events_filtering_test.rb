require 'application_system_test_case'
require 'tempfile'

class EventsFilteringTest < ApplicationSystemTestCase
  EVENTS_JSONL = <<~JSONL
    {"hook_event_type":"Stop","summary":"stop event","timestamp":1700000000,"source_app":"codex","session_id":"session-1"}
    {"hook_event_type":"UserPromptSubmit","summary":"prompt event","timestamp":1700000001,"source_app":"codex","session_id":"session-1"}
  JSONL

  def setup
    super
    @events_file = Tempfile.new(['events', '.jsonl'])
    @events_file.write(EVENTS_JSONL)
    @events_file.flush
    ENV['AGENTMEM_EVENTS_PATH'] = @events_file.path
  end

  def teardown
    ENV.delete('AGENTMEM_EVENTS_PATH')
    @events_file.close!
    super
  end

  test 'filter shows selected event type' do
    visit '/events'
    select 'Stop', from: 'hook_event_type'
    click_on 'Filter'

    within '.events' do
      assert_text 'Stop'
    end
  end

  test 'filter hides other event types' do
    visit '/events'
    select 'Stop', from: 'hook_event_type'
    click_on 'Filter'

    within '.events' do
      assert_no_text 'UserPromptSubmit'
    end
  end
end
