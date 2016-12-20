require "../binary_parser"

module EazyDB::Record
  class IndexHeader < BinaryParser
    uint32 :size
  end

  class IndexRecord < BinaryParser
    uint32 :offset
  end
end
