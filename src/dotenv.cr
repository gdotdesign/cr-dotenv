require "./dotenv/*"

module Dotenv
  extend self

  class FileMissing < Exception
  end

  @@verbose = true

  def verbose=(value : Bool) : Bool
    @@verbose = value
  end

  def load(filename = ".env") : Hash(String, String)
    load open(filename)
  rescue ex
    log "DOTENV - Could not open file: #{filename}"
    {} of String => String
  end

  def load(filenames : Array(String)) : Hash(String, String)
    filenames.each_with_object({} of String => String) do |filename, hash|
      hash.merge!(load(filename))
    end
  end

  def load(io : IO) : Hash(String, String)
    hash = {} of String => String
    io.each_line do |line|
      handle_line line, hash
    end
    load hash
    hash
  end

  def load(hash : Hash(String, String))
    hash.each do |key, value|
      ENV[key] = value
    end
    ENV
  end

  def load!(filename = ".env") : Hash(String, String)
    load open(filename)
  rescue ex
    raise FileMissing.new("Missing file!")
  end

  def load!(filenames : Array(String)) : Hash(String, String)
    filenames.each_with_object({} of String => String) do |filename, hash|
      hash.merge!(load!(filename))
    end
  end

  def load!(io : IO) : Hash(String, String)
    load(io)
  end

  def load!(hash : Hash(String, String))
    load(hash)
  end

  private def handle_line(line, hash)
    if line !~ /\A\s*(?:#.*)?\z/m
      name, value = line.split("=", 2)
      value = value.strip
      value = value.lchop('"').rchop('"') if value.starts_with?('"') && value.ends_with?('"')
      hash[name.strip] = value
    end
  rescue ex
    log "DOTENV - Malformed line #{line}"
  end

  private def log(message : String)
    puts message if @@verbose
  end

  private def open(filename : String) : File
    File.open(File.expand_path(filename))
  end
end
