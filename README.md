# MultiLogReader for Crystal

Concurrently reading multiple text files which are growing and may be rotated, such as unix system log files.

This provides almost same functions as [LogReader](https://github.com/arcage/crystal-logreader), but can read multiple files concurrently.

Of course, it works even with only one input file.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  multi_log_reader:
    github: arcage/multi_log_reader
```

## Usage

```crystal
require "multi_log_reader"

# puts lines from 2 input files.
MultiLogReader.new("a.log", "b.log").each do |line|
  puts line
end

# expands file names from the patterns for `Dir.glob`
MultiLogReader.new("*.log", "*_log").each do |line|
  puts line
end
```

For each input file:

- When the current file reaches EOF, this will wait new line added to the file. (like tail -f command)
- Even when the current file is rotated, this will trace new file and continue reading lines.

`MultiLogReader#each` will stop when all input files are missed. Here, "file is missed" means no readable file exists with given filename.

Except from avobe, it will continue to read new input.

If you want to stop it, you have to do that forcibly by using Ctrl+C, kill command etc.

### Callbacks

You can set a `Proc(String, Void)` type callback by `MultiLogReader.on_missing_file=`.
Whenever one of the input files is missed, the proc will be called with file path string of that file.

Similarly, you can set a `Proc(Void)` type callback by `MultiLogReader.on_missing_all=`.
This proc will be called when all input files are missed(before exiting `MultiLogReader#each`).

```crystal
require "multi_log_reader"

MultiLogReader.on_missing_file = ->(path : String) {
  STDERR.puts "[MultiLogReader] Input file #{path} is gone."
}

MultiLogReader.on_missing_all = ->() {
  STDERR.puts "[MultiLogReader] All input files are gone."
}

MultiLogReader.new("*_log").each do |line|
  puts line
end
```

## Contributors

- [arcage](https://github.com/arcage) ʕ·ᴥ·ʔAKJ - creator, maintainer
