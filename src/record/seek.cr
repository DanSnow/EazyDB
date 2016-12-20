module EazyDB::Record
  class Record
    def seek_to_record(io : IO, id : UInt32)
      if index?
        seek_with_index(io, id)
      else
        seek_linear(io, id)
      end
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
  end
end
