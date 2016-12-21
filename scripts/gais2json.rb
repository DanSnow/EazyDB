#!/usr/bin/env ruby
# encoding: UTF-8

require 'json'

obj = File.read(ARGV[0]).each_line.each_with_object([]) do |line, arr|
  case line
  when /^@GAISRec:/
    arr << {}
  when /^@U:/
    _, url = line.split(':', 2)
    arr.last[:url] = url.chomp
  when /^@T:/
    _, title = line.split(':', 2)
    arr.last[:title] = title.chomp
  when /^@B:/
    _, content = line.split(':', 2)
    arr.last[:content] = content
  else
    arr.last[:content] << line
  end
end

File.write("record.json", JSON.dump(obj))
