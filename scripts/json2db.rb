#!/usr/bin/env ruby
# encoding: UTF-8

require 'json'
require 'open3'

datas = JSON.load(File.read(ARGV[0]))
Open3.popen3(['../bin/eazydb', '-i']) do |stdin, stdout, stderr, thread|
  stdin.puts "use #{ARGV[1]}"
  datas.each do |data|
    stdin.puts "insert #{JSON.dump(data)}"
    break
  end
  stdin.puts "exit"
end
