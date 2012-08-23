#!/usr/bin/env ruby

require 'sequel'


DB = Sequel.connect("sqlite://survey.sqlite3")

DB.create_table :question_types do
  primary_key :id
  String :type
end

DB.create_table :questions do
  primary_key :id
  foreign_key :question_type_id, :question_types
  String :instructions
end

DB.create_table :work_functions do
  primary_key :id
  String :work_function
end

DB.create_table :hospices do
  primary_key :id
  String :name
end

DB.create_table :users do
  primary_key :id
  String :ip_address
  String :referrer
  Time :created_at
end

DB.create_table :answer_sets do
  primary_key :id
  Time :timestamp
  foreign_key :question_id, :questions
  foreign_key :user_id, :users
end

DB.create_table :rank_answers do
  primary_key :id
  foreign_key :answer_set_id, :answer_sets
  foreign_key :work_function_id, :work_functions
  Integer :rank
end

DB.create_table :multiple_selection_answers do
  primary_key :id
  foreign_key :answer_set_id, :answer_sets
  foreign_key :work_function_id, :work_functions
end

DB.create_table :hospice_answers do
  primary_key :id
  foreign_key :answer_set_id, :answer_sets
  foreign_key :hospice_id, :hospices
end

DB.create_table :comments do
  primary_key :id
  foreign_key :answer_set_id, :answer_sets
  String :comment
end

["Identifying patient's/family's unique psychosocial needs",
 "Assessing patient/family risk for psychosocial distress or complicated grief",
 "Assessing and enhancing patient/family strengths and coping skills",
 "Assessing and enhancing the responsiveness of the environment and connecting the patient, family, caregiver with community resources as needed",
 "Identifying psychosocial interventions to be offered as part of the evolving comprehensive plan of care developed in accordance with the patient's/family's wishes and the interdisciplinary team",
 "Providing intervention for specific symptom relief and to reduce risk for distress",
 "Assessing and managing psychosocial aspects of pain",
 "Screening for psychopathology and abuse and educating and intervening accordingly",
 "Evaluating the efficacy of treatment interventions",
 "Advocating for legislative and organizational policies and procedures that ensure access to quality care for all patients and families facing serious and life-limiting illnesses."].each {|work_function|
  DB[:work_functions].insert(:work_function => work_function)
}

[{:type => "rank"},
 {:type => "multiple selection"},
 {:type => "single selection or text entry"}].each { |row|
  DB[:question_types].insert(row)
}

questions_initial_data = [{:question_type_id => 3, :instructions => "Please select the hospice you are affiliated with."},
 {:question_type_id => 1, :instructions => "Please rank the work functions in terms of importance."},
 {:question_type_id => 1, :instructions => "Please rank the work functions in terms of which require the most work time."},
 {:question_type_id => 2, :instructions => "Please identify three functions from the list that are your personal/professional strengths."},
 {:question_type_id => 2, :instructions => "Please identify three functions from the list that you see to be areas for growth and skill development."}]

questions_initial_data.each {|row|
  DB[:questions].insert(row)
}

hospices_initial_data = [{:name => "HospiceCare of Boulder and Broomfield Counties"},
                         {:name => "The Denver Hospice"},
                         {:name => "Pathways Hospice"},
                         {:name => "Pikes Peak Hospice and Palliative Care"},
                         {:name => "Sangre de Cristo Hospice and Palliative Care"},
                         {:name => "Hospice of the Plains"},
                         {:name => "Hospice and Palliative Care of Western Colorado"}].each {|row|
  DB[:hospices].insert(row)
}

