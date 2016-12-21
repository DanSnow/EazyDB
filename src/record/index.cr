require "../binary_parser"

module EazyDB::Record
  class IndexHeader < BinaryParser
    uint32 :size
  end

  class IndexRecord < BinaryParser
    uint32 :offset
  end

  class Record
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
      reindex unless index?

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
  end
end
