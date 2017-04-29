require 'icalendar'

module Parrot
  class Occurrence
    attr_accessor :dstart, :dend, :candidate_list, :event, :original_date

    def initialize(dstart, dend, candidate_list,event)
      @dstart = dstart
      @dend = dend
      @candidate_list = candidate_list
      @event = event
      @original_date = dstart
    end
  end
end
