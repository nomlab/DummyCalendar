require 'icalendar'

module DummyCalendar
  class Occurrence
    attr_accessor :dstart, :dend, :event

    def initialize(dstart, dend, event)
      @dstart = dstart
      @dend = dend
      @event = event
    end
  end
end
