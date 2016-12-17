require "json"
require "./command"
require "../record"
require "../record/type"

module EazyDB::Commands
  alias Type = ::EazyDB::Record::Type

  class Create < Command
    def execute(args : JSON::Any)
      path = args["path"].as_s
      dir = File.dirname(path)
      fatal "Path \"#{dir}\" not exist" unless File.exists?(dir)
      Dir.mkdir(path)
      initdb(path, args["schema"])
    end

    private def initdb(path : String, schema_datas : JSON::Any)
      schema = schema_datas.map do |schema_data|
        name, type = schema_data.map(&.as_s)
        case type
        when "str"
          { name: name, type: Type::T_STR }
        when "num"
          { name: name, type: Type::T_NUM }
        else
          raise "Type error"
        end
      end
      ::EazyDB::Record::Record.initdb(path, schema)
    end
  end
end
