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
      puts "Header size: #{@header_size}"
      puts "Cols:"
      @schema.each do |key, type|
        case type
        when Type::T_STR
          puts "#{key}: str"
        when Type::T_NUM
          puts "#{key}: num"
        end
      end

      puts "\nRecord count: #{@record_count}"
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
