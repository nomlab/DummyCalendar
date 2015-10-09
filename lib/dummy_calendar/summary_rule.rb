# -*- coding: utf-8 -*-
require 'date'

module DummyCalendar
  module SummaryRule
    class Base
      def initialize(base_name)
        @base_name = base_name
      end

      def create(date)
      end
    end

    class NoMakeup < Base
      def initialize(base_name)
        super(base_name)
      end

      def create(date)
        return @base_name
      end
    end

    class Countup < Base
      def initialize(base_name)
        @n_th = 1
        super(base_name)
      end

      def create(date)
        s = '第' + @n_th.to_s + '回' + @base_name
        @n_th += 1
        return s
      end
    end

    class Year < Base
      def initialize(base_name)
        super(base_name)
      end

      def create(date)
        return business_year(date).to_s + '年度' + @base_name
      end

      private

      def business_year(date)
        return (1 <= date.month  && date.month  <= 3) ? date.year - 1 : date.year
      end
    end

    class YearAndCountup < Year
      def initialize(base_name)
        @n_th = 1
        super(base_name)
      end

      def create(date)
        year = business_year(date)
        if @prev_date
          d = Date.parse(year.to_s + '-04-01')
          @n_th = 1 if @prev_date < d && d <= date
        end

        s = year.to_s + '年度第' + @n_th.to_s + '回' + @base_name
        @prev_date = date
        @n_th += 1
        return s
      end
    end

    class Ambiguous
      # Not implement
    end
  end
end
