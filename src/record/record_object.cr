require "./type"
require "./meta"
require "../binary_parser"

module EazyDB::Record
  class RecordString < ::BinaryParser
    uint32 :size
    string :value
  end

  class RecordNumber < ::BinaryParser
    uint32 :size
    int32 :value
  end

  class RecordObject
    @keys = [] of String
    @type = {} of String => Type
    @value = {} of String => (String | Int32)

    def initialize(@meta : FileHeader)
      @meta.meta_cols.cols.each do |col|
        @keys << col.name
        @type[col.name] = Type.from_value(col.type)
      end
    end

    def write(io : IO)
      io.write_bytes(self)
    end

    def to_io(io : IO, format : IO::ByteFormat)
      @keys.each do |key|
        case @type[key]
        when Type::T_NUM
          rec = RecordNumber.new
          rec.value = @value[key].as(Int32)
          io.write_bytes(rec)
        when Type::T_STR
          rec = RecordString.new
          str = @value[key].as(String)
          rec.size = str.size.to_u32
          rec.value = str
          io.write_bytes(rec)
        end
      end
    end

    def []=(key : String, value : String)
      raise "Key not found" unless @keys.includes? key
      raise "Type mis-match" unless @type[key] == Type::T_STR
      @value[key] = value
    end

    def []=(key : String, value : Int32)
      raise "Key not found" unless @keys.include? key
      raise "Type mis-match" unless @type[key] == Type::T_NUM
      @value[key] = value
    end

    def [](key : String)
      @value[key]
    end
  end
end
