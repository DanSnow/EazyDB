require "json"
require "./command"
require "../record"

module EazyDB::Commands
  class CreateResponse < Response
    def initialize(@path : String)
    end

    def to_s
      "Success create db at #{@path}"
    end
  end

  class Create < Command
    def execute(args : JSON::Any?)
      args = args.not_nil!
      path = args["path"].as_s
      dir = File.dirname(path)
      fatal "Path \"#{dir}\" not exist" unless File.exists?(dir)
      Dir.mkdir(path)
      initdb(path, args["schema"])
      CreateResponse.new(path)
    end

    private def initdb(path : String, schema_datas : JSON::Any)
      schema = schema_datas.as_a.map do |schema_data|
        name, type = schema_data.as_a.map(&.as_s)
        p type
        case type
        when "str"
          {name: name, type: Type::T_STR}
        when "num"
          {name: name, type: Type::T_NUM}
        else
          fatal "Type error"
        end
      end
      ::EazyDB::Record::Record.initdb(path, schema)
    end
  end
end
