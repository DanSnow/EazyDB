require "../binary_parser"

module EazyDB::Record
  MAGIC = 0xA4D382CEu32
  REC_MAGIC = 0xFEEEu16

  class MetaCol < BinaryParser
    uint8 :type
    string :name, { count: 32 }
  end

  class MetaCols < BinaryParser
    uint32 :size
    array :cols, { type: MetaCol, count: :size }
  end

  class FileHeader < BinaryParser
    uint32 :magic
    type :meta_cols, MetaCols
    uint32 :next_id
    uint16 :rec_magic
  end
end
