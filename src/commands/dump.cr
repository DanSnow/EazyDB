require "json"
require "./command"

module EazyDB::Commands
  class DumpResponse < Response
    @ids = [] of UInt32
    @rec = {} of UInt32 => ::EazyDB::Record::RecordObject

    def []=(id : UInt32, rec_object : RecordObject)
      @ids << id
      @rec[id] = rec_object
    end

    def to_s
      String.build do |io|
        @ids.each do |id|
          io.puts "ID: #{id}"
          io << @rec[id].to_s
        end
      end
    end

    def to_json(json : JSON::Builder)
      json.object do
        json.field "error", true
        time_info(json)
      end
    end
  end

  class Dump < Command
    def execute(arg : JSON::Any?)
      res = DumpResponse.new
      db.dump do |header, rec_object|
        res[header.id] = rec_object
      end
      res
    end
  end
end
