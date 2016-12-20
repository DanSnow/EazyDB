require "c/fcntl"
require "./binary_parser"
require "./record/*"

module EazyDB::Record
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
      with_record do |io|
        check_header(io)
      end
    end

    def get(id : UInt32)
      check_id_range(id)

      with_record do |io|
        rec_header = seek_to_record(io, id)
        break nil if rec_header.nil?
        rec_object = create_record
        rec_object.load(io)
      end
    end

    def insert(record_object : RecordObject)
      with_record("w") do |io|
        id = increase_id(io)
        offset = append_record(io, id, record_object)
        update_index(id, offset.to_u32)
      end
    end

    def update(id : UInt32, record_object : RecordObject)
      check_id_range(id)

      with_record("w+") do |io|
        raise "Record not exist" unless mark_delete(io, id)
        offset = append_record(io, id, record_object)
        update_index(id, offset.to_u32)
      end
    end

    def delete(id : UInt32)
      check_id_range(id)

      with_record("w+") do |io|
        mark_delete(io, id)
        update_index(id, 0u32)
      end
    end

    def dump
      with_record do |io|
        rec_object = create_record
        each_record(io) do |header|
          yield header, rec_object.load(io)
        end
      end
    end

    def reindex
      with_index("w") do |index_io|
        idx_header = IndexHeader.new
        idx_header.size = header.next_id
        idx_header.write(index_io)
        idx_rec = IndexRecord.new
        idx_rec.offset = 0u32
        idx_header.size.times do
          idx_rec.write(index_io)
        end
        index_io.pos = 4

        with_record do |rec_io|
          each_record(rec_io, true) do |rec_header|
            idx_rec.offset = rec_io.pos.to_u32
            index_io.pos = index_offset(rec_header.id)
            idx_rec.write(index_io)
          end
        end
      end
    end

    def seek_to_record(io : IO, id : UInt32)
      if index?
        seek_with_index(io, id)
      else
        seek_linear(io, id)
      end
    end

    def seek_with_index(io : IO, id : UInt32)
      offset = find_offset(id)
      return nil unless offset
      return nil if offset == 0
      io.pos = offset
      RecHeader.new.load(io)
    end

    def find_offset(id : UInt32)
      return nil unless index?
      check_id_range(id)

      with_index do |io|
        io.pos = index_offset(id)
        idx = IndexRecord.new.load(io)
        idx.offset
      end
    end

    def update_index(id : UInt32, offset : UInt32)
      return reindex unless index?

      with_index("w+") do |io|
        io.pos = 0
        idx_header = IndexHeader.new.load(io)
        extend_index(io, header.next_id - idx_header.size) if idx_header.size < header.next_id
        io.pos = index_offset(id)
        idx = IndexRecord.new
        idx.offset = offset
        idx.write(io)
      end
    end

    def extend_index(io : IO, size : UInt32)
      io.seek(0, IO::Seek::End)
      fill_index(io, size)
    end

    def fill_index(io : IO, size : UInt32)
      idx = IndexRecord.new
      size.times do
        idx.write(io)
      end
    end

    def index?
      File.exists?(index_path)
    end

    def index_offset(id : UInt32)
      id * 4 + 4
    end

    def append_record(io : IO, id : UInt32, record_object : RecordObject)
      rec_header = create_rec_header(id, record_object.size)
      io.seek(0, IO::Seek::End)
      offset = io.pos
      rec_header.write(io)
      record_object.write(io)
      offset
    end

    def mark_delete(io : IO, id : UInt32)
      rec_header = seek_to_header(io, id)
      return false if rec_header.nil?
      rec_header.del = 1u8
      rec_header.write(io)
      true
    end

    def each_record(io, seek_header = false)
      io.pos = header.bytesize
      rec_header = RecHeader.new
      loop do
        rec_header.load(io)
        rec_pos = io.pos
        if rec_header.del == 0
          io.pos -= 13 if seek_header
          yield rec_header
        end
        io.pos = rec_pos + rec_header.next
      end
    rescue IO::EOFError
      nil
    end


    def seek_to_header(io : IO, id : UInt32)
      rec_header = seek_to_record(io, id)
      # RecHeader size = 13
      io.pos -= 13 if rec_header
      rec_header
    end

    def seek_linear(io : IO, id : UInt32)
      io.pos = header.bytesize
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

    def increase_id(io : IO)
      id = header.next_id
      header.next_id += 1
      write_meta(io)
      id
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
      with_file(record_path, flag) do |f|
        yield f
      end
    end

    def with_index(flag = "r")
      with_file(index_path, flag) do |f|
        yield f
      end
    end

    def with_file(filepath, flag)
      if flag == "r"
        File.open(filepath) do |f|
          yield f
        end
      else
        file = open_file(filepath, flag)
        begin
          yield file
        ensure
          file.close
        end
      end
    end

    def header
      @header.not_nil!
    end

    private def check_id_range(id)
      next_id = header.next_id
      raise "Index out of range" unless id < next_id
    end

    private def record_path
      File.join(@db_path, "rdbfile")
    end

    private def index_path
      File.join(@db_path, "rindex")
    end

    private def check_header(io : IO)
      @header = io.read_bytes(FileHeader).as(FileHeader)
      raise "Magic mis-match" if MAGIC != @header.not_nil!.magic
    end
  end
end

