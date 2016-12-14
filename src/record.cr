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

    def self.initdb(path : String, schemas : Array({ type: Type, name: String }))
      header = FileHeader.new
      header.magic = MAGIC
      header.rec_magic = REC_MAGIC
      header.next_id = 0u32

      header.meta_cols.size = schemas.size.to_u32
      schemas.each do |schema|
        col = MetaCol.new
        col.type = schema[:type].value
        col.name = schema[:name]
        header.meta_cols.cols << col
      end

      File.open("#{path}/rdbfile", "w") do |f|
        header.write(f)
      end
    end

    def initialize(filename : String)
      @filename = filename
      io = File.open(filename)
      check_header(io)
    end

    def create_record
      RecordObject.new(@header)
    end

    def write_record(record_obj : RecordObject)
    end

    private def check_header(io : IO)
      @header = io.read_bytes(FileHeader).as(FileHeader)
      raise "Magic mis-match" if MAGIC != header.magic
    end
  end
end

