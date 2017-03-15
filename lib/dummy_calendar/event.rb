# coding: utf-8
require 'date'
require 'icalendar'

module Parrot
  class Event
    attr_accessor :summary, :duration, :calendar

    def initialize(pattern, calendar)
      @summary = pattern["SUMMARY"]
      @duration = pattern["DURATION"]
      @calendar = calendar
      @random = Random.new
      @rec = generate_recurrence(pattern)
    end

    def next_generate_date
      return @rec.next_generate_date
    end

    def generate_occurrence
      date_list = @rec.calculate_next_date
      date = check_participant(date_list)
      if @msg == ""
        occ = Parrot::Occurrence.new(date, date, self)
      else
        e = self.clone
        e.summary = @msg + e.summary
        occ = Parrot::Occurrence.new(date, date, e)
      end
      @calendar.add_event(occ)

      gen_border = next_generate_date
      pre_ndate = @rec.next_date
      while 1
        break if @rec.timing == 'successively'
        date_list = @rec.calculate_next_date
        date = check_participant(date_list)
        if (date <=> gen_border) == 1
          @rec.next_date = pre_ndate
          break
        end
        if @msg == ""
          occ = Parrot::Occurrence.new(date, date, self)
        else
          e = self.clone
          e.summary = @msg + e.summary
          occ = Parrot::Occurrence.new(date, date, e)
        end
        @calendar.add_event(occ)
        pre_ndate = @rec.next_date
      end
    end

    private

    def generate_recurrence(pattern)
      start_date = set_start_date(pattern)
      rec = Parrot::Recurrence.new(summary, start_date)
      rec.define_parameters(pattern)
      return rec
    end

    def set_start_date(recurrence)
      start_date = ""
      if recurrence["DATE"]
        month, date = recurrence["DATE"][0].split('/')
        start_date = Date.new($dstart.year, month.to_i, date.to_i)
      elsif recurrence["MONTHWEEK"]
        month, week = recurrence["MONTHWEEK"][0].split('-')
        start_date = Date.new($dstart.year, month.to_i, (week.to_i-1)*7+@random.rand(1..7))
      elsif recurrence["MONTH"]
        month = recurrence["MONTH"][0]
        if month.to_i == 2
          start_date = Date.new($dstart.year, month.to_i, @random.rand(1..28))
        else
          start_date = Date.new($dstart.year, month.to_i, @random.rand(1..30))
        end
      else
        start_date = ($dstart + @random.rand(0..13))
      end
      start_date += 365 unless start_date.between?($dstart, $dend)
      return start_date
    end

    def check_participant(date_list)
      @msg = ""
      date_list.each do |date|
        score = 0
        @calendar.users.each do |user|
          if user.join?(date, @rec.duration)
            user.calendars.each do |cal, val|
              score += val if cal.name == @calendar.name
            end
          end
        end
        if score >= @calendar.border
          return date
        else
          cal_list = []
          @calendar.users.each do |user|
            user.calendars.each do |cal, val|
              cal_list << cal
            end
          end
          cal_list.uniq.each do |cal|
            cal.events.each do |event|
              if (event.dstart <=> date_list[0]) == 0
                puts "Overlap #{event.event.summary}"
                e = event.event.clone
                e.summary = "#{$overlap_count}.ex," + e.summary
                event.event = e
                @msg += "#{$overlap_count}.new,"
                $overlap_count += 1
              end
            end
          end
        end
      end
      # すべての候補日で参加者が閾値を超えない場合であるため，他の予定の入れ替え処理を行う必要がある
      return date_list[0] # FIXME
    end
  end
end
