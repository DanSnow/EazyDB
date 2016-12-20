require "json"
require "./command"

module EazyDB::Commands
  class Reindex < Command
    def execute(arg : JSON::Any?)
      db.reindex
      SuccessResponse.new("Success")
    end
  end
end
