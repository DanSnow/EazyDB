module EazyDB::Record
  class Record
    def write_meta(io)
      io.pos = 0
      header.write(io)
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

    private def record_path
      File.join(@db_path, "rdbfile")
    end

    private def index_path
      File.join(@db_path, "rindex")
    end
  end
end
