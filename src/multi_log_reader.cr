require "./multi_log_reader/*"

class MultiLogReader
  PIPE = Channel::Buffered(String).new

  @@on_missing_file : Proc(String, Void) = ->(path : String) {}
  @@on_missing_all : Proc(Void) = ->{}

  def self.on_missing_file=(proc : Proc(String, Void))
    @@on_missing_file = proc
  end

  def self.missing_file(path : String)
    @@on_missing_file.call(path)
  end

  def self.on_missing_all=(proc : Proc(Void))
    @@on_missing_all = proc
  end

  def self.missing_all
    @@on_missing_all.call
  end

  def initialize(*log_files)
    initialize(log_files)
  end

  def initialize(*log_files : Enumerable(String))
    @missing_all = false
    @log_files = [] of LogFile
    log_files.each do |pattern|
      Dir.glob(pattern).each do |path|
        @log_files << LogFile.new(path)
      end
    end
    raise Error.new("No file exist to read.") if @log_files.empty?
    start_reading
    start_checking_file_existence
  end

  def each
    until @missing_all
      if PIPE.empty?
        Fiber.yield
      else
        yield PIPE.receive
      end
    end
  end

  def start_reading
    @log_files.each(&.start_reading)
  end

  def start_checking_file_existence
    spawn do
      loop do
        break if missing_all?
        sleep(1.seconds)
      end
      MultiLogReader.missing_all
      @missing_all = true
    end
  end

  def missing_all?
    @log_files.each do |log_file|
      return false unless log_file.gone
    end
    return true
  end
end
