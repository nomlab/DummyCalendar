require 'date'
require 'icalendar'

module DummyCalendar
  class Event
    attr_accessor :summary, :dstart, :dend, :recurrence_tag, :timing, :during, :categories

    def initialize(summary, dstart, dend, recurrence_tag, timing, during, categories)
      @summary = summary
      @dstart = dstart
      @dend = dend
      @recurrence_tag = recurrence_tag
      @timing = timing
      @during = during
      @categories = categories
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
        e.categories = cal_name
      end
      cal.append_custom_property("X-TIMING","#{timing}")
      return cal.to_ical
    end
  end
end
