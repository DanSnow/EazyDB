require "json"
require "./command"

module EazyDB::Commands
  class Purge < Command
    def execute(arg : JSON::Any?)
      db.purge
      SuccessResponse.new("Success")
    end
  end
end
