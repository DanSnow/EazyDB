require "json"
require "./command"

module EazyDB::Commands
  class Update < Command
    def execute(arg : JSON::Any?)
      arg = arg.not_nil!
      id = arg["id"].as_i.to_u32
      value = arg["value"]
      rec_object = db.create_record
      rec_object.from_json(value)
      db.update(id, rec_object)
    end
  end
end
