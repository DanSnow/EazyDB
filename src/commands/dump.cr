require "json"
require "./command"

module EazyDB::Commands
  class Dump < Command
    def execute(arg : JSON::Any?)
      db.dump do |header, rec_object|
        puts "ID: #{header.id}"
        p rec_object
      end
    end
  end
end
