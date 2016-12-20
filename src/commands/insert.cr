require "json"
require "./command"

module EazyDB::Commands
  class Insert < Command
    def execute(arg : JSON::Any?)
      arg = arg.not_nil!
      record_object = db.create_record
      record_object.from_json(arg)
      db.insert(record_object)
      SuccessResponse.new("Success")
    end
  end
end
