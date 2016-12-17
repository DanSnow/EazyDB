require "json"
require "./command"

module EazyDB::Commands
  class Info < Command
    def execute(_arg : JSON::Any?)
      puts "Cols:"
      db.header.meta_cols.cols.each do |col|
        type = Type.from_value(col.type)
        case type
        when Type::T_STR
          puts "#{col.name}: str"
        when Type::T_NUM
          puts "#{col.name}: num"
        end
      end
      puts "\nRecord count: #{db.header.next_id}"
    end
  end
end
