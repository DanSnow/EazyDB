module EazyDB::Commands
  class StopExecute < Exception
  end

  abstract class Command
    abstract def execute(line : String)
    def run(line : String)
      begin
        execute(line)
      rescue StopExecute
        # Ignore
      end
    end

    def fatal(msg : String)
      STDERR.puts msg
      raise StopExecute.new
    end
  end

end
