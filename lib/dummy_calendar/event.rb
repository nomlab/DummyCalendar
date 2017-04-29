# coding: utf-8
require 'date'
require 'icalendar'

module Parrot
  class Event
    attr_accessor :summary, :duration, :calendar, :rec

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
      return if date_list.nil?
      date, ch_event = optimize_date(date_list)
      # if @msg == ""
      #   occ = Parrot::Occurrence.new(date, date, date_list, self)
      # else
      #   e = self.clone
      #   e.summary = @msg + e.summary
      #   occ = Parrot::Occurrence.new(date, date, date_list, e)
      # end
      occ = Parrot::Occurrence.new(date, date, date_list, self)
      @calendar.add_event(occ)
      ch_event.event.change_date(ch_event) if ch_event

      gen_border = next_generate_date
      pre_ndate = @rec.next_date
      while 1
        break if @rec.timing == 'successively'
        date_list = @rec.calculate_next_date
        return if date_list.nil?
        date, ch_event = optimize_date(date_list)
        if (date <=> gen_border) == 1
          @rec.next_date = pre_ndate
          break
        end
        ### TMP
        # if @msg == ""
        #   occ = Parrot::Occurrence.new(date, date, date_list, self)
        # else
        #   e = self.clone
        #   e.summary = @msg + e.summary
        #   occ = Parrot::Occurrence.new(date, date, date_list, e)
        # end
        ###
        occ = Parrot::Occurrence.new(date, date, date_list, self)
        @calendar.add_event(occ)
        ch_event.event.change_date(ch_event) if ch_event
        pre_ndate = @rec.next_date
      end
    end

    def change_date(event)
      event.candidate_list = event.candidate_list[1..-1]
      date, ch_event = optimize_date(event.candidate_list)
      puts "----#{event.dstart}, #{event.event.summary}"
      event.dstart = date
      event.dend = date
      puts "----#{event.dstart}"
      ch_event.event.change_date(ch_event) if ch_event
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

    def optimize_date(date_list)
      @msg = ""
      date = date_list.first
      p_score = 0
      @calendar.users.each do |user|
        if user.join?(date, @rec.duration)
          user.calendars.each do |cal, val|
            p_score += val if cal.name == @calendar.name
          end
        end
      end
      puts date, @summary
      puts p_score, @calendar.border
      puts p_score >= @calendar.border
      if p_score >= @calendar.border
        return date, nil
      else
        overlap_list = []
        $cals.each do |name, cal|
          cal.events.each do |event|
            if (event.dstart <=> date) == 0
              overlap_list << event
              ##### TMP
              # puts "Overlap #{event.event.summary}"
              # e = event.event.clone
              # e.summary = "#{$overlap_count}.ex," + e.summary
              # event.event = e
              # @msg += "#{$overlap_count}.new,"
              # $overlap_count += 1
              #####
            end
          end
        end
        min_c_score = 10000000
        ch_event = nil
        overlap_list.each do |event|
          c_score, dist_date = calc_score_if_changed(event.candidate_list, overlap_list, event)
          if min_c_score > c_score
            ch_event = event
            ch_date = dist_date
            min_c_score = c_score
          end
        end
        c_score, dist_date = calc_score_if_changed(date_list, overlap_list, nil)
        if min_c_score > c_score
          # ###### TMP
          # p_score = 0
          # date_list.each do |date|
          #   @calendar.users.each do |user|
          #     if user.join?(date, @rec.duration)
          #       user.calendars.each do |cal, val|
          #         p_score += val if cal.name == @calendar.name
          #       end
          #     end
          #   end
          #   if p_score >= @calendar.border
          #     return date
          #   end
          # end
          # #####
          return optimize_date(date_list[1..-1])
        else
          return date_list[0], ch_event
        end
      end
    end

    def calc_score_if_changed(candidate_list, event_list, changed_event)
      changed_p_score = 0
      if changed_event
        if changed_event.event.class != self.class # class is SingleEvent
          return 100000, changed_event.dstart
        end
        changed_event.event.calendar.users.each do |user|
          if user.join?(candidate_list[1], changed_event.event.rec.duration)
            user.calendars.each do |cal, val|
              changed_p_score += val if cal.name == changed_event.event.calendar.name
            end
          end
        end
        event_list.each do |e|
          next if e == changed_event
          if e.event.class != self.class # class is SingleEvent
            e.event.calendar.users.each do |user|
              user.calendars.each do |cal, val|
                changed_p_score += val if cal.name == e.event.calendar.name
              end
            end
          else
            e.event.calendar.users.each do |user|
              if user.join?(e.dstart, e.event.rec.duration)
                user.calendars.each do |cal, val|
                  changed_p_score += val if cal.name == e.event.calendar.name
                end
              end
            end
          end
        end

        diff = (candidate_list[1] - candidate_list[0]).abs
        reliability_score = changed_event.event.rec.interval[:param].n / diff

        days_left = changed_event.dstart - $now
        if days_left != 0
          left_score = 1 / days_left
        else
          left_score = 0
        end

        num_user = changed_event.event.calendar.users.length

        return changed_p_score + reliability_score*100 + left_score*100 + num_user*50, candidate_list[1]
      else
        @calendar.users.each do |user|
          if user.join?(candidate_list[1], @rec.duration)
            user.calendars.each do |cal, val|
              changed_p_score += val if cal.name == @calendar.name
            end
          end
        end
        event_list.each do |e|
          if e.class != self.class # class is SingleEvent
            e.event.calendar.users.each do |user|
              user.calendars.each do |cal, val|
                changed_p_score += val if cal.name == e.event.calendar.name
              end
            end
          else
            e.event.calendar.users.each do |user|
              if user.join?(e.dstart, e.event.rec.duration)
                user.calendars.each do |cal, val|
                  changed_p_score += val if cal.name == e.event.calendar.name
                end
              end
            end
          end
        end
        diff = (candidate_list[1] - candidate_list[0]).abs
        reliability_score = @rec.interval[:param].n / diff
        return changed_p_score + reliability_score*100, candidate_list[1]
      end
    end
  end
end
