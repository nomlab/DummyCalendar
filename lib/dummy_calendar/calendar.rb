require 'icalendar'

module DummyCalendar
  class Calendar
    attr_accessor :events

    def initialize
      @events = []
    end

    def add_event(event)
      @events << event
    end

    def add_events(events)
      events.each do |e|
        add_event(e)
      end
    end

    def to_ics
      cal = Icalendar::Calendar.new
      events.each do |dummy_event|
        cal.event do |e|
          e.dtstart     = Icalendar::Values::Date.new(dummy_event.dstart)
          e.dtend       = Icalendar::Values::Date.new(dummy_event.dend)
          e.summary     = dummy_event.summary
          e.description = ''
        end
      end
      return cal.to_ical
    end

    def print_events
      events.each do |e|
        puts e.pretty_print
      end
    end
  end
end
