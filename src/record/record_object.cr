require "json"
require "./type"
require "./meta"
require "../binary_parser"

module EazyDB::Record
  class RecordString < ::BinaryParser
    uint32 :size
    string :value, { count: :size }
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
        name = col.name
        @keys << name
        @type[name] = Type.from_value(col.type)
      end
    end

    def load(io : IO)
      @keys.each do |key|
        rec = case @type[key]
              when Type::T_NUM
                RecordNumber.new
              when Type::T_STR
                RecordString.new
              else
                raise "Type error"
              end
        rec.load(io)
        if rec.is_a? RecordNumber
          @value[key] = rec.value
        elsif rec.is_a? RecordString
          @value[key] = rec.value
        end
      end
      self
    end

    def write(io : IO)
      io.write_bytes(self)
    end

    def from_json(json : JSON::Any)
      @keys.each do |key|
        if json[key].as_i?
          self[key] = json[key].as_i
        elsif json[key].as_s?
          self[key] = json[key].as_s
        end
      end
    end

    def to_json(io : IO)
      io.json_object do |obj|
        @keys.each do |key|
          obj.field key, @value[key]
        end
      end
    end

    def to_io(io : IO, format : IO::ByteFormat)
      fullfill!

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

    def []=(key : String, value : String | Int32)
      raise "Key not found" unless @keys.includes? key
      case @type[key]
      when Type::T_STR
        self[key] = value.as(String)
      when Type::T_NUM
        self[key] = value.as(Int32)
      end
    end

    def []=(key : String, value : String)
      raise "Key not found" unless @keys.includes? key
      raise "Type mis-match" unless @type[key] == Type::T_STR
      @value[key] = value
    end

    def []=(key : String, value : Int32)
      raise "Key not found" unless @keys.includes? key
      raise "Type mis-match" unless @type[key] == Type::T_NUM
      @value[key] = value
    end

    def [](key : String)
      @value[key]
    end

    def size
      fullfill!

      @keys.reduce(0) do |total, key|
        case @type[key]
        when Type::T_NUM
          total + 8
        when Type::T_STR
          str = @value[key].as(String)
          total + 4 + str.size
        else
          total
        end
      end
    end

    def fullfill!
      unfilled = unfilled_keys
      raise "Col #{unfilled.inspect} missing" unless unfilled.empty?
    end

    def unfilled_keys
      @keys.reject { |key| @value.has_key? key }
    end

    def each
      fullfill!

      @keys.each do |key|
        yield key, @value[key]
      end
    end

    def to_s
      String.build do |io|
        each do |key, value|
          io.puts "#{key}: #{value}"
        end
      end
    end
  end

  class Record
    def create_record
      RecordObject.new(header)
    end
  end
end
