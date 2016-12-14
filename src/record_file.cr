require "./binary_parser"
require "./record/*"

module EazyDB::Record
  class RecHeader < BinaryParser
    uint32 :id
    uint32 :ctime
    uint8 :del
    uint32 :next
  end

  class Record
    getter :filename

    def self.initdb(path : String)
      header = FileHeader.new
      header.magic = MAGIC
      header.rec_magic = REC_MAGIC
      header.meta_cols.size = 1u32
      header.next_id = 1u32
      col = MetaCol.new
      col.type = Type::T_STR.value
      col.name = "hello"
      header.meta_cols.cols << col
      rec_header = RecHeader.new
      rec_header.id = 0u32
      obj = RecordObject.new(header)
      obj["hello"] = "world"
      File.open("#{path}/rdbfile", "w") do |f|
        header.write(f)
        rec_header.write(f)
        f.write_bytes(obj)
      end
    end

    def initialize(filename : String)
      @filename = filename
      io = File.open(filename)
      check_header(io)
    end

    private def check_header(io : IO)
      @header = io.read_bytes(FileHeader).as(FileHeader)
      raise "Magic mis-match" if MAGIC != header.magic
    end
  end
end

