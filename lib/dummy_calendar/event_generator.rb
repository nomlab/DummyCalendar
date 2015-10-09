module DummyCalendar
  class SummaryRuleBuilder
    def self.create(base_name, rule)
      case rule
      when :no_makeup        then return DummyCalendar::SummaryRule::NoMakeup.new(base_name)
      when :countup          then return DummyCalendar::SummaryRule::Countup.new(base_name)
      when :year             then return DummyCalendar::SummaryRule::Year.new(base_name)
      when :year_and_countup then return DummyCalendar::SummaryRule::YearAndCountup.new(base_name)
      when :ambiguous        then return DummyCalendar::SummaryRule::Ambiguous.new(base_name)
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

  class EventGenerator
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

    def set_summary_rule(base_name, rule)
      @summary_rule = DummyCalendar::SummaryRuleBuilder.create(base_name, rule)
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
      result = [DummyCalendar::Event.new(@summary_rule.create(next_dstart), next_dstart, next_dstart)]

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

        result << DummyCalendar::Event.new(@summary_rule.create(next_dstart), next_dstart, next_dstart)

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
