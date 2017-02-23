require 'date'
require 'icalendar'

module DummyCalendar
  class Event
    attr_accessor :summary, :calendar, :users, :dstart, :dend

    def initialize(summary, calendar, users, dstart, dend, pattern)
      @summary = summary
      @calendar = calendar
      @users = users
      @dstart = dstart
      @dend = dend
      @random = Random.new
      @rec = generate_recurrence(pattern)
    end

    def generate_occurrence
      date_list = @rec.calculate_next_date
      date = check_participant(date_list)
      occ = DummyCalendar::Occurrence.new(date, self)
      @calendar.add_event(occ)
    end

    private

    def generate_recurrence(pattern)
      start_date = set_start_date(pattern)
      rec = DummyCalendar::Recurrence.new(categories, start_date)
      rec.define_parameters(dstart, pattern)
      return rec
    end

    def set_start_date(recurrence)
      start_date = ""
      if recurrence["DATE"]
        month, date = recurrence["DATE"][0].split('/')
        start_date = format("%02d-%02d", month.to_i, date.to_i)
      elsif recurrence["MONTHWEEK"]
        month, week = recurrence["MONTHWEEK"][0].split('-')
        start_date = format("%02d-%02d", month.to_i, (week.to_i-1)*7+@random.rand(1..7))
      elsif recurrence["MONTH"]
        month = recurrence["MONTH"][0]
        if month.to_i == 2
          start_date = format("%02d-%02d", month.to_i, @random.rand(1..28))
        else
          start_date = format("%02d-%02d", month.to_i, @random.rand(1..30))
        end
      else
        start_date = (dstart + @random.rand(0..13)).strftime("%m-%d")
      end
      return start_date
    end

    def check_participant(date_list)
      # WIP
    end
  end
end
