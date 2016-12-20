require "json"
require "./command"

module EazyDB::Commands
  class DeleteResponse < Response
    def initialize(@result : Bool, @id : UInt32)
      @error = !@result
    end

    def to_s
      if @result
        "Success delete id: #{@id}"
      else
        "No such id: #{@id}"
      end
    end
  end

  class Delete < Command
    def execute(arg : JSON::Any?)
      arg = arg.not_nil!
      id = arg["id"].as_i.to_u32
      DeleteResponse.new(db.delete(id), id)
    end
  end
end
