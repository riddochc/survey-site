#!/usr/bin/env ruby

require './models.rb'
require 'erb'
require 'geoip'

def get_answers(question, timerange = [])
  querydata = {:question => question}
  timesql = case timerange
            when [] then ""
            else
              if timerange.length == 2
                querydata[:starting] = timerange[0]
                querydata[:ending] = timerange[1]
                "and timestamp between :starting and :ending"
              end
            end
  type = case question
         when 1 then :hospice
         when 2 then :multiple_selection
         when 3 then :multiple_selection
         when 4 then :rank
         when 5 then :rank
         when 6 then :comment
         else :error
         end

  column_list = case type
                when :rank then "work_function_id, rank"
                when :multiple_selection then "work_function_id"
                when :hospice then "hospice_id"
                when :comment then "comment"
                end
  table_list = case type
               when :rank then "rank_answers"
               when :multiple_selection then "multiple_selection_answers"
               when :hospice then "hospice_answers"
               when :comment then "comments"
               end

  sql = %Q{select user_id, timestamp, #{column_list}
    from answer_sets, #{table_list}
    where answer_sets.user_id not in (select test_users())
      and answer_sets.question_id = :question
      and #{table_list}.answer_set_id = answer_sets.id
      #{timesql}
    ;}

  DB.fetch(sql, querydata)
end

def ranked_or_selected(question, timerange = [])
  rankings = {}
  get_answers(question, timerange).to_hash_groups(:user_id).each do |user_answerset|
    user_num = user_answerset[0]
    ranked_work_functions = user_answerset[1].each.sort {|a, b|
        a[:rank] <=> b[:rank] }.map {|m|
           m[:work_function_id] }
    rankings[user_num] = ranked_work_functions
  end
  rankings
end

class Time
  def readable
    self.strftime('%A, %B %d at %I:%M %p')
  end
end

erbinput = File.open('views/daily_report.erb', 'r').read

from = Time.at(Time.now() - (60 * 60 * ARGV[0].to_i))
to = Time.now()
geo = GeoIP.new('GeoLiteCity.dat')

hospice_answers = get_answers(1, [from, to] ).all.group_by {|a| a[:hospice_id] }

q6 = get_answers(6, [from, to] ).all


erb = ERB.new(erbinput, nil, "%<>")
erb.run(binding)


