require "json"
require "./command"

module EazyDB::Commands
  class Reindex < Command
    def execute(arg : JSON::Any?) : SuccessResponse
      db.reindex
      SuccessResponse.new("Success")
    end
  end
end
