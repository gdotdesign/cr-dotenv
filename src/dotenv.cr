require "./dotenv/*"

module Dotenv
  extend self

  @@verbose = true

  def verbose=(value : Bool) : Bool
    @@verbose = value
  end

  def load(path = ".env") : Hash(String, String)
    load File.open(File.expand_path(path))
  rescue ex
    log "DOTENV - Could not open file: #{path}"
    {} of String => String
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
  end

  private def handle_line(line, hash)
    name, value = line.split("=")
    hash[name.strip] = value.strip
  rescue ex
    log "DOTENV - Malformed line #{line}"
  end

  private def log(message : String)
    puts message if @@verbose
  end
end
