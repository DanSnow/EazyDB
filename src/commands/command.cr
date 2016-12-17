require "json"
require "../record"

require "../record/type"

module EazyDB::Commands
  class StopExecute < Exception
  end

  alias Type = ::EazyDB::Record::Type

  abstract class Command
    @db : ::EazyDB::Record::Record?

    def initialize(@db)
    end

    abstract def execute(args : JSON::Any?)

    def run(line : String?)
      begin
        if line
          execute(JSON.parse(line))
        else
          execute(nil)
        end
      rescue StopExecute
        # Ignore
      end
    end

    def fatal(msg : String)
      STDERR.puts msg
      raise StopExecute.new
    end

    protected def db
      if @db
        @db.not_nil!
      else
        fatal "No db select"
      end
    end
  end

end
