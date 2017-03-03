require 'date'
require 'icalendar'

module Parrot
  class SingleEvent
    attr_accessor :summary, :duration, :calendar

    def initialize(summary, duration, calendar)
      @summary = summary
      @duration = duration
      @calendar = calendar
    end
  end
end
