#!/usr/bin/env ruby

require 'sinatra'
require 'erb'
require 'sequel'
require 'sinatra/cookies'

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
  erb :step, :locals => {:s => step}
end

post %r{^/step/(\d+)} do |i|
  # Do some processing...
  puts "Processing step #{i}"
  next_step = i.to_i.succ
  next_path = "/step/#{next_step}"
  redirect next_path, 302
end



