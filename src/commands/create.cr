require "./command"
require "../record_file"

module EazyDB::Commands
  class Create < Command
    def execute(line : String)
      dir = File.dirname(line)
      fatal "Path \"#{dir}\" not exist" unless File.exists?(dir)
      Dir.mkdir(line)
      initdb(line)
    end

    private def initdb(path : String)
      ::EazyDB::Record::Record.initdb(path)
    end
  end
end
