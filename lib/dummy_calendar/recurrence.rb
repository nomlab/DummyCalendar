# coding: utf-8
require "rubygems"
require 'yaml'
require 'date'
require 'icalendar'
require 'json'

module DummyCalendar
  class Recurrence
    attr_accessor :summary, :next_date, :interval, :duration, :timing

    def initialize(summary, next_date)
      @summary = summary
      @next_date = next_date
      @params = []
    end

    def define_parameters(recurrence)
      set_cal_name(cal_name)
      set_interval(recurrence["INTERVAL"]) if recurrence["INTERVAL"]
      set_duration(recurrence["DURATION"]) if recurrence["DURATION"]
      set_timing(recurrence["TIMING"]) if recurrence["TIMING"]
      set_wday(recurrence["WDAY"]) if recurrence["WDAY"]
      set_holiday(recurrence["HOLIDAY"]) if recurrence["HOLIDAY"] != nil
      set_monthweek(recurrence["MONTHWEEK"]) if recurrence["MONTHWEEK"]
      set_month(recurrence["MONTH"]) if recurrence["MONTH"]
      set_date(recurrence["DATE"]) if recurrence["DATE"]
      set_vacation_term(recurrence["VACATION_TERM"], dstart) if recurrence["VACATION_TERM"]
      set_hidden_events(recurrence["HIDDEN_EVENTS"]) if recurrence["HIDDEN_EVENTS"] != nil
      set_order(recurrence["ORDER"]) if recurrence["ORDER"]
      set_deadline(recurrence["DEADLINE"]) if recurrence["DEADLINE"]
    end

    def calculate_next_date
      dates = $dstart..($dend + 366).step(1).to_a

      # Evaluate all params without interval param
      vals_params = evaluation_values(dates, @next_date)

      vals_interval = @interval[:param].evaluation_values(dates, @next_date)
      vals_total = vals_params.zip(vals_interval).map{|f,s| f + s * @interval[:weight]}
      index_of_pivot = (@next_date + @interval[:param].n - range.first).to_i
      candidate_list = []
      while 1
        indexes_of_candidate = indexes_of_max(vals_total)
        @next_date_index = closest(indexes_of_candidate, index_of_pivot)
        break if vals_total[@next_date_index] < 3
        participant_val = 0
        vals_total[@next_date_index] -= 100
      end

      if candidate_list.length == 0
      end

      @next_date = $dstart + candidate_list[0]

      return candidate_list
    end

    def next_generate_date
      if @timing == 'successively'
        return @next_date
      else
        dates = []
        @timing.each do |timing|
          month, date = timing.split('/')
          d = Date.new(@next_date, month.to_i, date.to_i)
          dates << d
        end
        dates.sort!
        dates.each do |d|
          next if d <=> @next_date == -1
          return d
        end
        return dates[0].next_year
        else
          return d
        end
      end
    end

    private

    def add_param(name, opt, weight)
      @params << {:param  => DummyCalendar::ParamBuilder.create(name, opt),
                  :weight => weight}
    end

    def set_cal_name(name)
      @cal_name = name
    end

    def set_interval(interval)
      if interval.to_i < 14
        range = 3
      elsif interval.to_i < 120
        range = 7
      else
        range = 15
      end
      opt = {:n => interval, :range => ((-1)*range)..range}
      @interval = {:param  => DummyCalendar::ParamBuilder.create(:interval, opt),
                   :weight => 2}
    end

    def set_duration(duration)
      @duration = duration
    end

    def set_timing(timing)
      @timing = timing
    end

    def set_wday(wday)
      wday.each do |w|
        add_param(:wday, {:wday => :w, :flag => true}, 1)
      end
    end

    def set_holiday(holiday)
      add_param(:holiday, {:flag => holiday}, 5)
    end

    def set_monthweek(monthweek)
      monthweek.each do |mw|
        month, week = mw.split('-')
        add_param(:monthweek, {:month => month, :week => week, :flag => true}, 1)
      end
    end

    def set_month(month)
      month.each do |m|
        add_param(:month, {:month => m, :flag => true}, 1)
      end
    end

    def set_date(date)
      date.each do |d|
        month, day = d.split('/')
        add_param(:date, {:month => month, :day => day, :flag => true}, 1)
      end
    end

    def set_vacation_term(vacation_term)
      ($dstart.yaer..$dend.year).each do |year|
        vacation_term.each do |term|
          first, last = term.split('-')
          st = Date.new(dstart.year, first.split('/')[0].to_i, first.split('/')[1].to_i)
          en = Date.new(dstart.year, last.split('/')[0].to_i, last.split('/')[1].to_i)
          if st < en
          add_param(:vacation_term, {:dstart => Date.parse("#{year}-#{st.strftime("%m-%d")}"), :dend => Date.parse("#{year}-#{en.strftime("%m-%d")}")}, 5)
          else # dendの方が日付が若い場合，dendを1年延ばす．
          add_param(:vacation_term, {:dstart => Date.parse("#{year}-#{st.strftime("%m-%d")}"), :dend => Date.parse("#{year + 1}-#{en.strftime("%m-%d")}")}, 5)
          end
        end
      end
    end

    def set_hidden_events(other_events)
      if other_events
        add_param(:other_events, {:n => 50, :seed => 999999}, 5)
      end
    end

    def set_order(order)
      ($dstart.year..$dend.year).each do |year|
        if order["AFTER"]
          order["AFTER"].each do |date|
            month, day = date.split('/')
            add_param(:order, {:date => Date.parse("#{year}-#{format("%02d-%02d", month, day)}"), :direction => :after}, 1)
          end
        end
        if order["SIMULTANEOUS"]
          order["SIMULTANEOUS"].each do |date|
            month, day = date.split('/')
            dc.add_param(:order, {:date => Date.parse("#{year}-#{format("%02d-%02d", month, day)}"), :direction => :simultaneous}, 1)
          end
        end
        if order["BEFORE"]
          order["BEFORE"].each do |date|
            month, day = date.split('/')
            add_param(:order, {:date => Date.parse("#{year}-#{format("%02d-%02d", month, day)}"), :direction => :before}, 1)
          end
        end
      end
    end

    def set_deadline(deadline)
      ($dstart.year..$dend.year).each do |year|
        deadline.each do |dl|
          month, day = dl.split('/')
          dc.add_param(:deadline, {:date => Date.parse("#{year}-#{format("%02d-%02d", month, day)}")}, 1)
        end
      end
    end

    def evaluation_values(dates, dstart)
      seq = Array.new(dates.length, 0)
      @params.each do |param|
        vals = param[:param].evaluation_values(dates)
        seq = seq.zip(vals).map{|f,s| f + s * param[:weight]}
      end
      return seq
    end

    def indexes_of_max(arr)
      return arr.map.with_index{|x, i| i if x == arr.max}.compact
    end

    def closest(data, val)
      return data.min_by{|x| (x-val).abs}.to_i
    end
  end
end
