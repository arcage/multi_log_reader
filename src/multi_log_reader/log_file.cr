class MultiLogReader
  private class LogFile
    @path : String
    @io : File
    @missed : Bool

    getter path
    getter missed

    def initialize(@path)
      @missed = false
      @io = open_file
    end

    def start_reading
      spawn do
        eof_count = 0
        bytes = [] of UInt8
        until @missed
          byte = @io.read_byte
          if byte
            eof_count = 0
            if byte == 10
              line = String.new(Bytes.new(bytes.to_unsafe, bytes.size))
              send(line)
              bytes.clear
              Fiber.yield
            else
              bytes << byte
            end
          else
            eof_count += 1
            if eof_count > 4
              check_file
              eof_count = 0
            else
              sleep(1)
            end
          end
        end
      end
    end

    private def ino
      @io.stat.ino
    end

    private def send(line : String)
      while PIPE.full?
        sleep(1.milliseconds)
      end
      PIPE.send(line)
    end

    private def check_file
      @io = reopen_file if ino != File.stat(@path).ino
    rescue
      MultiLogReader.missing_file(@path)
      @missed = true
    end

    private def open_file : File
      if File.file?(@path) && File.readable?(@path)
        File.open(@path)
      else
        raise FileUnreadable.new(@path)
      end
    end

    private def reopen_file : File
      @io.close unless @io.closed?
      open_file
    end
  end
end
