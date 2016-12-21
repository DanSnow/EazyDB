#!/usr/bin/env ruby
# encoding: UTF-8

require 'json'
require 'open3'
require 'securerandom'

schema = [
  ['str1', 'str'],
  ['str2', 'str'],
  ['str3', 'str']
]

create_data = {
  path: 'db/dbtest-str',
  schema: schema
}

datas = Array.new(100000) do
  {
    str1: SecureRandom.hex(rand(10..50)),
    str2: SecureRandom.hex(rand(10..50)),
    str3: SecureRandom.hex(rand(10..50))
  }
end

Open3.popen2e('./eazydb -i') do |stdin, stdout_stderr, thread|
  Thread.new do
    stdout_stderr.each do |l|
      puts l
    end
  end
  stdin.puts "create #{JSON.dump(create_data)}"
  stdin.puts 'use db/dbtest-str'
  datas.each do |data|
    stdin.puts "insert #{JSON.dump(data)}"
  end
  stdin.puts "exit"
  stdin.close
  thread.join
end
