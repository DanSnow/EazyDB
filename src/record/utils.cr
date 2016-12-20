require "c/fcntl"

module EazyDB::Record
  class Record
    def open_file(filepath, flag)
      mode = if flag == "w+"
               LibC::O_RDWR
             else
               LibC::O_WRONLY
             end
      oflag = mode | LibC::O_CLOEXEC | LibC::O_CREAT
      fd = LibC.open(filepath, oflag, File::DEFAULT_CREATE_MODE)
      file = IO::FileDescriptor.new(fd, blocking: true)
    end
  end
end
