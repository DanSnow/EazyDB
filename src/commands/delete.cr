require "json"
require "./command"

module EazyDB::Commands
  class Delete < Command
    def execute(arg : JSON::Any?)
      arg = arg.not_nil!
      p db.delete(arg["id"].as_i.to_u32)
    end
  end
end
