require "c/fcntl"
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

    def get(id : UInt32)
      next_id = header.next_id
      raise "Index out of range" unless id < next_id
      with_record do |io|
        rec_header = seek_to_record(io, id)
        break nil if rec_header.nil?
        rec_object = create_record
        rec_object.load(io)
      end
    end

    def insert(record_object : RecordObject)
      with_record("w") do |io|
        id = header.next_id
        header.next_id += 1
        write_meta(io)
        rec_header = create_rec_header(id, record_object.size)
        io.seek(0, IO::Seek::End)
        rec_header.write(io)
        record_object.write(io)
      end
    end

    def delete(id : UInt32)
      next_id = header.next_id
      raise "Index out of range" unless id < next_id
      with_record("w+") do |io|
        rec_header = seek_to_header(io, id)
        break false if rec_header.nil?
        rec_header.del = 1u8
        rec_header.write(io)
        true
      end
    end

    def seek_to_header(io : IO, id : UInt32)
      rec_header = seek_to_record(io, id)
      io.pos -= 13 if rec_header
      rec_header
    end

    def seek_to_record(io : IO, id : UInt32)
      io.pos = 0
      io.read_bytes(FileHeader) # Jump header
      rec_header = RecHeader.new
      rec_header.load(io)
      while rec_header.id != id || rec_header.del != 0
        io.pos += rec_header.next
        rec_header.load(io)
      end
      rec_header
    rescue IO::EOFError
      nil
    end

    def create_record
      RecordObject.new(@header.not_nil!)
    end

    def create_rec_header(id, size)
      rec_header = RecHeader.new
      rec_header.id = id
      rec_header.ctime = Time.now.epoch.to_u32
      rec_header.del = 0u8
      rec_header.next = size.to_u32
      rec_header
    end

    def write_meta(io)
      io.seek(0, IO::Seek::Set)
      @header.not_nil!.write(io)
    end

    def with_record(flag = "r", &block)
      if flag == "r"
        File.open(record_path) do |f|
          yield f
        end
      else
        mode = if flag == "w+"
                 LibC::O_RDWR
               else
                 LibC::O_WRONLY
               end
        oflag = mode | LibC::O_CLOEXEC
        fd = LibC.open(record_path, oflag, File::DEFAULT_CREATE_MODE)
        file = IO::FileDescriptor.new(fd, blocking: true)
        begin
          yield file
        ensure
          file.close
        end
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

