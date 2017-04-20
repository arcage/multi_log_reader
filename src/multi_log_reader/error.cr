class MultiLogReader
  class Error < Exception; end

  class FileUnreadable < Error
    def initialize(path : String)
      super("#{path} is not a file or unreadable.")
    end
  end
end
