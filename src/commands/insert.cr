require "json"
require "./command"

module EazyDB::Commands
  class Insert < Command
    def execute(arg : JSON::Any)
      record_object = db.create_record
      record_object.from_json(arg)
      db.insert(record_object)
      puts "Done insert #{arg}"
    end
  end
end
