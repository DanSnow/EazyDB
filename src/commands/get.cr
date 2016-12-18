require "json"
require "./command"

module EazyDB::Commands
  class Get < Command
    def execute(arg : JSON::Any?)
      arg = arg.not_nil!
      p db.get(arg["id"].as_i.to_u32)
    end
  end
end
