require "../binary_parser"

module EazyDB::Record
  class RecHeader < BinaryParser
    uint32 :id
    uint32 :ctime
    uint8 :del
    uint32 :next
  end

  class Record
    def create_rec_header(id, size)
      rec_header = RecHeader.new
      rec_header.id = id
      rec_header.ctime = Time.now.epoch.to_u32
      rec_header.del = 0u8
      rec_header.next = size.to_u32
      rec_header
    end
  end
end

