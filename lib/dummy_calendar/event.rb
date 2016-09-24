require 'date'
require 'icalendar'

module DummyCalendar
  class Event
    attr_accessor :summary, :dstart, :dend, :recurrence_tag, :timing, :during

    def initialize(summary, dstart, dend, recurrence_tag, timing, during)
      @summary = summary
      @dstart = dstart
      @dend = dend
      @recurrence_tag = recurrence_tag
      @timing = timing
      @during = during
    end

    def pretty_print
      return dstart.strftime("%Y/%m/%d") + ', ' + recurrence_tag + ', ' + summary
    end

    def to_ical
      cal = Icalendar::Calendar.new
      cal.event do |e|
        e.dtstart     = Icalendar::Values::Date.new(dstart)
        e.dtend       = Icalendar::Values::Date.new(dend)
        e.summary     = summary
        e.description = ''
      end
      cal.append_custom_property("X-TIMING","#{timing}")
      return cal.to_ical
    end
  end
end
