#!/usr/bin/env ruby

require 'sinatra'
require 'erb'
require 'sequel'
require 'sinatra/cookies'

class NoSuchQuestion < Exception
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
  case question[:question_type_id]
  when 1
    erb :rank, :locals => {:q => question, :s => step}
  when 2
    erb :multiple_selection, :locals => {:q => question, :s => step}
  when 3
    erb :single_selection_or_text_entry, :locals => {:q => question, :s => step}
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
