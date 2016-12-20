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
        res = mark_delete(io, id)
        update_index(id, 0u32)
        res
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
  end
end

