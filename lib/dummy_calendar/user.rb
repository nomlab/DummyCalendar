require 'icalendar'

module DummyCalendar
  class User
    attr_accessor :name, :calendars

    def initialize(name, calendars)
      @name = name
      @calendars = calendars
    end

    def reserved_time(dstart)
      return time
    end
  end
end
