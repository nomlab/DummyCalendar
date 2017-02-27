require 'icalendar'

module DummyCalendar
  class Calendar
    attr_accessor :name, :border, :users, :events

    def initialize(name, border)
      @name = name
      @border = border
      @users = []
      @events = []
    end

    def add_user(user)
      @users << user
    end

    def add_event(event, range, users)
      users.each do |name, val|
        if $used_time[name][event.dstart]
          $used_time[name][event.dstart] += event.during
        else
          $used_time[name][event.dstart] = event.during
        end
      end
      @events << event if event.dstart.between?(range.first, range.last)
    end

    def add_events(events, range, users)
      events.each do |e|
        add_event(e, range, users)
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
          e.append_custom_property("X-TIMING","#{dummy_event.timing}")
        end
      end
      return cal.to_ical
    end

    def print_events
      events.each do |e|
        puts e.pretty_print
      end
    end

    def add_non_reccrence(max_time, range, name, users)
      path = File.expand_path("../../../generated/non_rec_#{name}.ics", __FILE__)
      f = File.open(path)
      event = Icalendar.parse(f, true)
      devents = []
      event.events.each do |e|
        devent = DummyCalendar::Event.new(e.summary, e.dtstart, e.dtstart, 'no_reccring_event', 'bulk', max_time, name)
        devents << devent
      end
      add_events(devents, range, users)
    end
  end
end
