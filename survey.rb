#!/usr/bin/env ruby

require 'sinatra'
require 'erb'
require 'sequel'
require 'sinatra/cookies'
require 'json'

class NoSuchQuestion < Exception
end

class InvalidInput < Exception
end

#set :server, :thin
DB = Sequel.connect('sqlite://survey.sqlite3')
enable :sessions
set :session_secret, "something long and hard to guess"

# If the browser isn't already from around here, start them 
# at the right place, make a new user, and give a cookie.
before do
  if ((session[:ip_address] != request.ip) or
      (session[:created_at] < (Time.now() - 60 * 10))) # Session older than 10 minutes?
    puts "This looks like a new user!"
    session[:ip_address] = request.ip
    session[:created_at] = Time.now()
    user_id = DB[:users].insert(:ip_address => request.ip,
                          :referrer => request.referrer,
                          :created_at => session[:created_at])
    session[:user_id] = user_id
    redirect "/step/1", 302
  end
end

get %r{^/step/(\d+)} do |i|
  step = i.to_i
  question = DB[:questions][:id => step]
  if question.nil?
    raise NoSuchQuestion, step
  end
  r = Random.new((Time.now.to_f * 1000).to_i)
  case question[:question_type_id]
  when 1
    work_fns = DB[:work_functions].sort_by { r.rand }.to_a
    session[:work_function_order] = work_fns.map {|wf| wf[:id]}
    erb :rank, :locals => {:q => question, :s => step, :seed => r.seed, :work_fns => work_fns}
  when 2
    work_fns = DB[:work_functions].sort_by { r.rand }.to_a
    session[:work_function_order] = work_fns.map {|wf| wf[:id]}
    erb :multiple_selection, :locals => {:q => question, :s => step, :work_fns => work_fns}
  when 3
    completions = DB[:hospices].order(:name).map {|h| h[:name] }.to_json
    erb :single_selection_or_text_entry,
      :locals => {:q => question, :s => step,
                  :c => completions}
  else
    "Oops."
  end
  # erb :step, :locals => {:s => step}
end

post %r{^/step/(\d+)} do |i|
  step = i.to_i
  question = DB[:questions][:id => step]
  if question.nil?
    raise NoSuchQuestion, step
  end
  number_of_questions = DB[:questions].count
  if step > number_of_questions
    raise NoSuchQuestion, step
  end

  case step
  when 1
    puts "Processing step 1, got text: " + params["ac-input"]
    if params["ac-input"] =~ /^([A-Za-z' ]+)$/  # No funny characters in the name.
      cleaned_input = $1
    else
      raise InvalidInput
    end
    hospice = DB[:hospices][:name => cleaned_input]
    if hospice.nil?
      hospice_id = DB[:hospices] << {:name => cleaned_input}
    else
      hospice_id = hospice[:id]
    end
    user = session[:user_id]
    answer_set_id = DB[:answer_sets].insert(:timestamp => Time.now(), :question_id => question[:id], :user_id => user)
    answer_id = DB[:hospice_answers].insert(:answer_set_id => answer_set_id, :hospice_id => hospice_id)
    puts "Recorded answer: #{answer_id}"
  else
    "Oops."
  end

  # Process answer for question
  
  if (step < number_of_questions)
    next_step = i.to_i.succ
    next_path = "/step/#{next_step}"
    redirect next_path, 302
  elsif (number_of_questions == step)
    redirect "/done", 302
  else
    "Hmm. Not sure what to do here."
  end
end

get "/done" do
  erb :done
end
