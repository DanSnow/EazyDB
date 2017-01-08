require "json"
require "./command"

module EazyDB::Commands
  class InfoResponse < Response
    @schema = {} of String => Type

    def initialize(@record_count : UInt32, @header_size : Int32)
    end

    def []=(key : String, type : Type)
      @schema[key] = type
    end

    def to_s
      String.build do |io|
        io.puts "Header size: #{@header_size}"
        io.puts "Cols:"
        @schema.each do |key, type|
          case type
          when Type::T_STR
            io.puts "#{key}: str"
          when Type::T_NUM
            io.puts "#{key}: num"
          end
        end

        io.puts "\nRecord count: #{@record_count}"
      end
    end

    def to_json(json : JSON::Builder)
      json.object do
        json.field "error", false
        json.field "header", @header_size
        json.field "size", @record_count
        time_info(json)
        json.field "schema" do
          json.array do
            json.object do
              @schema.each do |key, type|
                json.field "name", key
                case type
                when Type::T_STR
                  json.field "type", "str"
                when Type::T_NUM
                  json.field "type", "num"
                end
              end
            end
          end
        end
      end
    end
  end

  class Info < Command
    def execute(_arg : JSON::Any?)
      res = InfoResponse.new(db.header.next_id, db.header.bytesize)

      db.header.meta_cols.cols.each do |col|
        type = Type.from_value(col.type)
        res[col.name] = type
      end

      res
    end
  end
end
