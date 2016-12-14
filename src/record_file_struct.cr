lib LibRecord
  struct FileHeader
    magic : UInt32
    meta_cols : MetaCols
  end

  enum Type : UInt8
    T_STR
    T_NUM
  end

  struct MetaCols
    size : Int32
    # cols : MetaCol*
  end

  struct MetaCol
    name : Char[32]
    type : Type
  end

  struct Record
    header : RecHeader
    # cols : Col*
  end


  struct RecHeader
    id : Int32
    ctime : Int32
    del : Int8
  end

  struct Col
    size : Int32
    # content : ColContent
  end
end

MAGIC = 0xA4D382CE

class Record
  def initialize(private @filename : String?)
    if @filename
      load_record
    end
  end

  def load(filename)
    @filename = filename
    load_record
  end

  private def load_record
    header = LibRecord::FileHeader.new
    header_size = sizeof(LibRecord::FileHeader)
    File.open(@filename.not_nil!) do |f|
      buf = Slice(UInt8).new(header_size)
      f.read(buf)
      buf.copy_to(pointerof(header).as(Pointer(UInt8)), header_size)
    end
    if header.magic != MAGIC
      raise "File format not correct"
    end
  end
end
