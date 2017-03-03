require 'icalendar'

module Parrot
  class User
    attr_accessor :name, :calendars

    def initialize(name, calendars)
      @name = name
      @calendars = calendars
    end

    def join?(date, duration)
      time = 0
      @calendars.each do |cal, val|
        time += cal.time_of_date(date)
      end
      if time + duration <= $max_time
        return true
      else
        return false
      end
    end
  end
end
