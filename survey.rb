#!/usr/bin/env ruby

require 'sinatra'
require 'pg'

conn = PG.connection.new(dbname: 'survey')

get %r{^/step/(\d+)} do |i|
  "Currently on step #{i}<p><form method=\"post\" action=\"/step/#{i}\"><input type=\"submit\"/></form></p>"
end

post %r{^/step/(\d+)} do |i|
  # Do some processing...
  puts "Processing step #{i}"
  next_step = i.to_i.succ
  next_path = "/step/#{next_step}"
  redirect next_path, 302
end

