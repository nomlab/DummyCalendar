# -*- coding: utf-8 -*-
require 'date'
require 'holidays'
require 'icalendar'

module Parrot
  dir = File.dirname(__FILE__) + "/dummy_calenda"
  autoload :Calendar,            "#{dir}/calendar.rb"
  autoload :Event,               "#{dir}/event.rb"
  autoload :Recurrence,          "#{dir}/recurrence.rb"
  autoload :Occurrence,          "#{dir}/occurrence.rb"
  autoload :User,                "#{dir}/user.rb"
  autoload :Param,               "#{dir}/param.rb"
  autoload :SummaryRule,         "#{dir}/summary_rule.rb"
end
