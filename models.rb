#!/usr/bin/env ruby

require 'yaml'
require 'logger'
require 'sequel'

config = YAML.load_file("/etc/surveyconfig.yaml")
config[:logger] = Logger.new('db.log')
DB = Sequel.connect(config)

class Users < Sequel::Model
  one_to_many :answer_sets
end

class QuestionTypes < Sequel::Model
  one_to_many :questions
end

class Questions < Sequel::Model
  many_to_one :question_types
  one_to_many :answer_sets
end

class WorkFunctions < Sequel::Model
  one_to_many :rank_answers
  one_to_many :multiple_selection_answers
end

class Hospices < Sequel::Model
  one_to_many :hospice_answers
end

class AnswerSets < Sequel::Model
  many_to_one :user
  one_to_many :rank_answers
  one_to_many :multiple_selection_answers
  one_to_one :hospice_answers
  one_to_one :comments
end

class RankAnswers < Sequel::Model
  many_to_one :work_functions
end

class MultipleSelectionAnswers < Sequel::Model
  many_to_one :work_functions
end

class HospiceAnswers < Sequel::Model
 many_to_one :hospices
 one_to_one :answer_sets
end

class Comments < Sequel::Model
  one_to_one :answer_sets
end


# RankAnswers.where(:answer_set_id => 4).order(:rank).map(:work_function_id)
# # -> A list of the work functions, ordered by their rank, in answer_set 4.
# real_users = AnswerSets.select(:user_id).where(:id => Comments.select(:answer_set_id).where(Sequel.~(:comment => /test/i)))
#
#answers = AnswerSets.select(:users__id, :timestamp, :question_id).join(:users, :id => :user_id).all
#HospiceAnswers.join(:answer_sets, :id => :answer_set_id).all

#HospiceAnswers.join(:answer_sets, :id => :answer_set_id).join(:users, :id => :user_id).all

#Users.join(:answer_sets, :user_id => :id).each {|r|
#}


