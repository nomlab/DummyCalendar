# coding: utf-8
require 'icalendar'
require 'json'
require 'securerandom'

module Parrot
  class Calendar
    attr_accessor :name, :border, :users, :events

    def initialize(name, border, rate)
      @name = name
      @border = border
      @users = []
      @events = []
      @random = Random.new
      add_single_event(rate)
    end

    def add_user(user)
      @users << user
    end

    def time_of_date(date)
      time = 0
      @events.each do |e|
        time += e.event.duration if (e.dstart <=> date) == 0
      end
      return time
    end

    def add_event(event)
      @events << event if event.dstart.between?($orig_range.first, $orig_range.last)
    end

    # def add_events(events, range, users)
    #   events.each do |e|
    #     add_event(e, range, users)
    #   end
    # end

    def to_ics
      cal = Icalendar::Calendar.new
      events.each do |dummy_event|
        cal.event do |e|
          e.dtstart     = Icalendar::Values::Date.new(dummy_event.dstart)
          e.dtend       = Icalendar::Values::Date.new(dummy_event.dend)
          e.summary     = dummy_event.event.summary
          e.description = ''
        end
      end
      return cal.to_ical
    end

    def to_json
      json = []
      events.each do |e|
        hash = {}
        hash["id"] = SecureRandom.uuid.upcase
        hash["allDay"] = true
        hash["title"] = e.event.summary
        hash["start"] = e.dstart.to_s
        hash["end"] = e.dend.to_s
        hash["className"] = ["parrot-#{name}"]
        json << hash
      end
      return json.to_json
    end

    # def print_events
    #   events.each do |e|
    #     puts e.pretty_print
    #   end
    # end

    private

    # 単発の予定をランダムに生成する．
    # 単発の予定同士の重複を考慮できていない．
    def add_single_event(rate)
      day = 0
      while $dend > ($dstart + day) do
        create_day = $dstart + day
        if really_event_generate?(rate)
          event = event_generate(create_day)
          self.add_event(event)
        end
        day += 1
      end
    end

    def event_generate(create_day)
      event = Parrot::SingleEvent.new('単発の予定', $max_time, self)
      occ = Parrot::Occurrence.new(create_day, create_day, [create_day], event)
      return occ
    end

    # probability generating an event by a day is (events_par_month / 31)
    def really_event_generate?(events_par_month)
      return true if (@random.rand(1..31) < events_par_month)
      return false
    end
  end
end
