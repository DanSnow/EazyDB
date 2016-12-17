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
    getter :db_path

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

    def initialize(@db_path : String)
      io = open_record
      check_header(io)
      io.close
    end

    def insert(record_object : RecordObject)
      with_record("w") do |io|
        id = header.next_id
        header.next_id += 1
        write_header(io)
        header = create_rec_header(id)
        io.seek(0, IO::Seek::End)
        header.write(io)
        record_object.write(io)
      end
    end

    def create_record
      RecordObject.new(@header.not_nil!)
    end

    def create_rec_header(id)
      rec_header = RecHeader.new
      rec_header.id = id
      rec_header.ctime = Time.now.epoch.to_u32
      rec_header.del = 0u8
      rec_header
    end

    def write_header(io)
      io.rewind
      @header.not_nil!.write(io)
    end

    def with_record(flag = "r", &block)
      File.open(record_path, flag) do |f|
        yield f
      end
    end

    def open_record
      File.open(record_path)
    end

    def write_record(io : IO, record_obj : RecordObject)
    end

    def header
      @header.not_nil!
    end

    private def record_path
      File.join(@db_path, "rdbfile")
    end

    private def check_header(io : IO)
      @header = io.read_bytes(FileHeader).as(FileHeader)
      raise "Magic mis-match" if MAGIC != @header.not_nil!.magic
    end
  end
end

