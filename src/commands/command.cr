require "json"
require "../record"

require "../record/type"

module EazyDB::Commands
  class FatalError < Exception
  end

  alias Type = ::EazyDB::Record::Type
  alias RecordObject = ::EazyDB::Record::RecordObject

  abstract class Response
    @error : Bool = false
    setter time : Time::Span?

    abstract def to_s

    def to_json(json : JSON::Builder)
      json.object do
        json.field "error", @error
        json.field "message", to_s
        time_info(json)
      end
    end

    def time_info(json : JSON::Builder)
      json.field "time", @time.not_nil!.to_s
    end

    def error?
      @error
    end
  end

  class SuccessResponse < Response
    def initialize(@msg : String)
    end

    def to_s
      @msg
    end
  end

  class ErrorResponse < Response
    @error = true

    def initialize(@msg : String)
    end

    def to_s
      @msg
    end
  end

  abstract class Command
    @db : ::EazyDB::Record::Record?

    def initialize(@db)
    end

    abstract def execute(args : JSON::Any?) : Response

    def run(line : String?)
      if line
        execute(JSON.parse(line))
      else
        execute(nil)
      end
    rescue err : FatalError
      ErrorResponse.new(err.message || "")
    rescue err : JSON::ParseException | KeyError
      ErrorResponse.new("Argument error")
    end

    def fatal(msg : String)
      STDERR.puts msg
      raise FatalError.new(msg)
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
