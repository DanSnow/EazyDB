require "json"
require "./command"

module EazyDB::Commands
  class GetResponse < Response
    def initialize(@id : UInt32, @rec_object : RecordObject)
    end

    def to_s
      String.build do |io|
        io.puts "ID: #{@id}"
        io << @rec_object.to_s
      end
    end

    def to_json(json : JSON::Builder)
      json.object do
        json.field "error", false
        json.field "data" do
          @rec_object.to_json(json)
        end
        time_info(json)
      end
    end
  end

  class Get < Command
    def execute(arg : JSON::Any?)
      arg = arg.not_nil!
      id = arg["id"].as_i.to_u32
      rec_object = db.get(id)
      if rec_object
        GetResponse.new(id, rec_object)
      else
        ErrorResponse.new("Record #{id} not found")
      end
    end
  end
end
