# -*- coding: utf-8 -*-
require 'date'
require 'holidays'

module RubyProf
  def profiler(&block)
    result = RubyProf.profile &block
    printer = RubyProf::FlatPrinter.new(result)
    strio = StringIO.new
    printer.print(strio)
    strio.string
  end
  module_function :profiler
end

module DummyCalendar
  module Param
    class Term
      def initialize(dstart, dend, flag)
        @dstart = dstart; @dend = dend; @flag = flag ? 1 : -1
      end

      def evaluation_values(dates)
        candidates = (@dstart..@dend).to_a
        arr = Array.new(dates.length, 0)
        candidates.each do |candidate|
          index = dates.index(candidate)
          arr[index] = @flag unless index.nil?
        end
        return arr
      end
    end

    class Interval
      attr_accessor :n

      # n     : Interval of up to next start date. So called generally cycle.
      # range : Range to be able to select as candidates of next start date.
      #         pivot = previous_start_date + n
      #         candidates = pivot + range
      def initialize(n, range)
        @n = n; @range = range
      end

      def evaluation_values(dates, dstart)
        d = dates.first; tail = dates.length - 1
        arr = Array.new(dates.length, 0)
        indexes = @range.map{|i| dstart - d + @n + i}
        indexes.select!{|i| 0 <= i && i <= tail}
        indexes.each do |i|
          arr[i] = 1
        end
        return arr
      end
    end

    class Wday
      def initialize(wday, flag)
        @wday = {:Sun=>0, :Mon=>1, :Tue=>2, :Wed=>3, :Thu=>4, :Fri=>5, :Sat=>6}[wday]
        @flag = flag ? 1 : -1
      end

      def evaluation_values(dates)
        return dates.map{|date| date.wday == @wday ? @flag : 0}
      end
    end

    # `Holiday` is Sat, Sun, and public holiday.
    class Holiday
      def initialize(flag)
        @flag = flag ? 1 : -1
      end

      def evaluation_values(dates)
        return dates.map{|date| my_holiday?(date) ? @flag : 0}
      end

      private

      def my_holiday?(date)
        return date.wday == 0 || date.wday == 6 || date.holiday?(:jp)
      end
    end

    class Monthweek
      def initialize(month, week, flag)
        @month = month; @week = week; @flag = flag ? 1 : -1
      end

      def evaluation_values(dates)
        return dates.map{|date| monthweek?(date, @month, @week) ? @flag : 0}
      end

      private

      def monthweek?(date, month, week)
        return (date.month == month) && ((date.day - 1) / 7 == (week - 1))
      end
    end

    class Month
      def initialize(month,  flag)
        @month = month; @flag = flag ? 1 : -1
      end

      def evaluation_values(dates)
        return dates.map{|date| date.month == @month ? @flag : 0}
      end
    end

    class Date
      def initialize(month, day,  flag)
        @month = month; @day = day; @flag = flag ? 1 : -1
      end

      def evaluation_values(dates)
        return dates.map{|date| date.month == @month && date.day == @day ? @flag : 0}
      end
    end

    class VacationTerm
      def initialize(dstart, dend)
        @dc = DummyCalendar::Param::Term.new(dstart, dend, false)
      end

      def evaluation_values(dates)
        return @dc.evaluation_values(dates)
      end
    end

    class OtherEvents
      # n    : Number of business trip between 1 year
      # seed : Seed value for Random
      def initialize(n, seed)
        @n = n; @seed = Random.new(seed)
      end

      def evaluation_values(dates)
        n = (((dates.last - dates.first) / 365).to_f * @n).to_i
        arr = Array.new(dates.length, 0)
        indexes = (0..(arr.length-1)).to_a.shuffle(:random => @seed)[1..n]
        indexes.each do |index|
          arr[index] = 1
        end
        return arr
      end
    end

    class Order
      def initialize(date, direction)
        @date = date; @direction = direction
      end

      def evaluation_values(dates)
        case @direction
        when :before        then return dates.map{|date| date < @date ? 1 : 0}
        when :simultaneous  then return dates.map{|date| date == @date ? 1 : 0}
        when :after         then return dates.map{|date| date > @date ? 1 : 0}
        end
      end
    end
  end

  class ParamBuilder
    def self.create(name, opt)
      case name
      when :interval      then return DummyCalendar::Param::Interval.new(opt[:n], opt[:range])
      when :wday          then return DummyCalendar::Param::Wday.new(opt[:wday], opt[:flag])
      when :holiday       then return DummyCalendar::Param::Holiday.new(opt[:flag])
      when :monthweek     then return DummyCalendar::Param::Monthweek.new(opt[:month], opt[:week], opt[:flag])
      when :month         then return DummyCalendar::Param::Month.new(opt[:month], opt[:flag])
      when :date          then return DummyCalendar::Param::Date.new(opt[:month], opt[:day], opt[:flag])
      when :vacation_term then return DummyCalendar::Param::VacationTerm.new(opt[:dstart], opt[:dend])
      when :other_events  then return DummyCalendar::Param::OtherEvents.new(opt[:n], opt[:seed])
      when :order         then return DummyCalendar::Param::Order.new(opt[:date], opt[:direction])
      when :simultaneous  then return DummyCalendar::Param::Order.new(opt[:date], :simultaneous)
      when :deadline      then return DummyCalendar::Param::Order.new(opt[:date], :before)
      end
    end
  end

  class Generator
    def initialize
      @params = []
    end

    def set_interval(opt, weight)
      @interval = {:param  => DummyCalendar::ParamBuilder.create(:interval, opt),
                   :weight => weight}
    end

    def add_param(name, opt, weight)
      @params << {:param  => DummyCalendar::ParamBuilder.create(name, opt),
                  :weight => weight}
    end

    def generate(dstart, range)
      unless @interval
        puts 'Error: Interval parameter is required. You must call set_interval()'
        exit -1
      end

      # Set dates with excess of range. Reason is following.
      # When selecting next_dstart around last of range,
      # not being able to select date after range.
      # Thus, next_dstart is forcibly selected within range.
      dates = ((range.first)..(range.last + 30)).step(1).to_a

      next_dstart = dstart
      result = [next_dstart]

      # Evaluate all params without interval param
      vals_params = evaluation_values(dates, dstart)

      while 1
        vals_interval = @interval[:param].evaluation_values(dates, next_dstart)
        vals_total = vals_params.zip(vals_interval).map{|f,s| f + s * @interval[:weight]}

        index_of_pivot = (next_dstart + @interval[:param].n - range.first).to_i
        indexes_of_candidate = indexes_of_max(vals_total)
        next_dstart_index = closest(indexes_of_candidate, index_of_pivot)

        break if next_dstart >= dstart + next_dstart_index
        next_dstart = range.first + next_dstart_index
        break if next_dstart > range.last
        result << next_dstart

        vals_params = Array.new(next_dstart_index + 1, -999) + vals_params[(next_dstart_index+1)..-1]
      end

      return result
    end

    private

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
