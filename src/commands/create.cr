require "./command"
require "../record"
require "../record/type"

module EazyDB::Commands
  alias Type = ::EazyDB::Record::Type

  class Create < Command
    def execute(line : String)
      path, schema_datas = line.split(' ')
      dir = File.dirname(path)
      fatal "Path \"#{dir}\" not exist" unless File.exists?(dir)
      Dir.mkdir(path)
      initdb(path, schema_datas)
    end

    private def initdb(path : String, schema_datas : String)
      schema = schema_datas.split(',').map do |schema_data|
        name, type = schema_data.split(':')
        case type
        when "str"
          { name: name, type: Type::T_STR }
        when "num"
          { name: name, type: Type::T_NUM }
        else
          raise "Parse error"
        end
      end
      ::EazyDB::Record::Record.initdb(path, schema)
    end
  end
end
