require 'icalendar'

module DummyCalendar
  class User
    attr_accessor :used_time

    def initialize
      @used_time = []
    end

    def add_time(dstart, time)
      if @used_time
        @used_time[dstart] += time
      else
        @used_time[dstart] = time
      end
    end

    def move_time(src, dest, time)
      @used_time[src] -= time
      add_time(dest, time)
    end

    def show_time(dstart)
      return @used_time[dstart]
    end
  end
end
