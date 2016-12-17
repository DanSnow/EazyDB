require "json"
require "../record"

module EazyDB::Commands
  class StopExecute < Exception
  end

  abstract class Command
    @db : ::EazyDB::Record::Record?

    def initialize(@db)
    end

    abstract def execute(args : JSON::Any)

    def run(line : String)
      begin
        execute(JSON.parse(line))
      rescue StopExecute
        # Ignore
      end
    end

    def fatal(msg : String)
      STDERR.puts msg
      raise StopExecute.new
    end

    protected def db
      @db.not_nil!
    end
  end

end
