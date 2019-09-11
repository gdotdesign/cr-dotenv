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
    load parse_file(filename)
  rescue ex
    log "DOTENV - Could not open file: '#{filename}'"
    {} of String => String
  end

  def load(filenames : Array(String)) : Hash(String, String)
    newvars = filenames.each_with_object({} of String => String) do |filename, hash|
      begin
        hash.merge!(parse_file(filename))
      rescue ex : Errno
        log "DOTENV - Could not open file: '#{filename}'"
      end
    end
    load(newvars)
    newvars
  end

  def load(io : IO) : Hash(String, String)
    hash = parse(io)
    load(hash)
    hash
  end

  def load(hash : Hash(String, String)) : Hash(String, String)
    hash.each do |key, value|
      unless ENV.has_key?(key)
        ENV[key] = value
      end
    end
    hash
  end

  def load!(filename = ".env") : Hash(String, String)
    load parse_file(filename)
  rescue ex
    raise FileMissing.new("Missing file! '#{filename}'")
  end

  def load!(filenames : Array(String)) : Hash(String, String)
    newvars = filenames.each_with_object({} of String => String) do |filename, hash|
      begin
        hash.merge!(parse_file(filename))
      rescue ex : Errno
        raise FileMissing.new("Missing file! '#{filename}'")
      end
    end
    load(newvars)
    newvars
  end

  def load!(io : IO) : Hash(String, String)
    load(io)
  end

  def load!(hash : Hash(String, String))
    load(hash)
  end

  private def parse_file(filename : String) : Hash(String, String)
    hash = Hash(String, String).new
    File.each_line filename do |line|
      handle_line line, hash
    end
    hash
  end

  private def parse(io : IO) : Hash(String, String)
    hash = Hash(String, String).new
    io.each_line do |line|
      handle_line line, hash
    end
    hash
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
end
