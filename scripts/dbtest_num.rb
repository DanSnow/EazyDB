#!/usr/bin/env ruby
# encoding: UTF-8

require 'json'
require 'open3'

schema = [
  ['num1', 'num'],
  ['num2', 'num'],
  ['num3', 'num']
]

create_data = {
  path: 'db/dbtest-num',
  schema: schema
}

datas = Array.new(100000) do
  {
    num1: rand(100000),
    num2: rand(100000),
    num3: rand(100000)
  }
end

Open3.popen2e('./eazydb -i') do |stdin, stdout_stderr, thread|
  Thread.new do
    stdout_stderr.each do |l|
      puts l
    end
  end
  stdin.puts "create #{JSON.dump(create_data)}"
  stdin.puts 'use db/dbtest-num'
  datas.each do |data|
    stdin.puts "insert #{JSON.dump(data)}"
  end
  stdin.puts "exit"
  stdin.close
  thread.join
end
