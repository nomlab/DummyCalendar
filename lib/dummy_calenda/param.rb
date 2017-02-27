require 'date'
require 'holidays'

module Parrot
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
        @dc = Parrot::Param::Term.new(dstart, dend, false)
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
          arr[index] = -1
        end
        return arr
      end
    end

    class Order
      # Example: Order.new(Date.parse('2000-1-7', :before, 2))
      #---------------------------------------------------------------
      #              Date: ..., 2000-1-4, 1-5, 1-6, 1-7, 1-8, 1-9, ...
      # evaluation_values: ...,        0,   1,   1,   0,   0,   0, ...
      def initialize(date, direction, term_length = 30)
        @date = date; @direction = direction; @term_length = term_length
      end

      def evaluation_values(dates)
        case @direction
        when :before        then return dates.map{|date| (@date - @term_length <= date && date < @date) ? 1 : 0}
        when :simultaneous  then return dates.map{|date| date == @date ? 1 : 0}
        when :after         then return dates.map{|date| (@date + @term_length >= date && date > @date) ? 1 : 0}
        end
      end
    end
  end
end
