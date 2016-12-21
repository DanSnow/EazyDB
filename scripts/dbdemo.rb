#!/usr/bin/env ruby
# encoding: UTF-8

require 'json'
require 'set'
require 'open3'
require 'thread'
require 'securerandom'

schema = [
  ['num', 'num'],
  ['str', 'str']
]

create_data = {
  path: 'db/dbdemo',
  schema: schema
}

datas = Array.new(1000) do
  {
    num: rand(1000000),
    str: SecureRandom.hex(rand(10..50))
  }
end

Open3.popen2e('./eazydb -i') do |stdin, stdout_stderr, thread|
  t = Thread.new do
    stdout_stderr.each do |l|
      puts l
      break if l.match(/.*get.*/)
    end
  end
  fiber = Fiber.new do
    loop do
      id = Fiber.yield
      break if id.nil?
      unverifyed = Set.new([:id, :num, :str])
      stdout_stderr.each do |line|
        puts line
        break if unverifyed.empty?
        case line
        when /^ID:/
          unverifyed.delete(:id)
          raise "ID mismatch" if line.chomp != "ID: #{id}"
        when /^num:/
          unverifyed.delete(:num)
          raise "NUM mismatch" if line.chomp != "num: #{datas[id][:num]}"
        when /^str:/
          unverifyed.delete(:str)
          raise "STR mismatch" if line.chomp != "str: #{datas[id][:str]}"
        end
      end
    end
  end
  stdin.puts "create #{JSON.dump(create_data)}"
  stdin.puts 'use db/dbdemo'
  datas.each do |data|
    stdin.puts "insert #{JSON.dump(data)}"
  end

  fiber.resume

  Array.new(100) do
    id = rand(0...1000)
    stdin.puts %(get {"id": #{id}})
    t.join
    fiber.resume(id)
  end
  fiber.resume nil
  stdin.puts "exit"
  stdin.close
  thread.join
end
