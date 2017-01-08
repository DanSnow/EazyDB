module EazyDB::Record
  class Record
    def increase_id(io : IO)
      id = header.next_id
      header.next_id += 1
      write_meta(io)
      id
    end

    def header
      @header.not_nil!
    end

    private def check_id_range(id)
      next_id = header.next_id
      raise "Index out of range" unless id < next_id
    end

    private def check_header(io : IO)
      @header = io.read_bytes(FileHeader).as(FileHeader)
      raise "Magic mis-match" if MAGIC != @header.not_nil!.magic
    end
  end
end
