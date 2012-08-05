#!/usr/bin/env ruby

require 'sinatra'
require 'erb'

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

