module Dotenv
  extend self

  class FileMissing < Exception
  end

  @@verbose = true

  def verbose=(value : Bool) : Bool
    @@verbose = value
  end

  # Loads environment variables from a `String` into the `ENV` constant.
  #
  # ```
  # require "dotenv"
  #
  # hash = Dotenv.load_string "VAR=Hello"
  # hash #=> {"VAR" => "Hello"}
  # ```
  def load_string(env_vars : String) : Hash(String, String)
    hash = Hash(String, String).new
    env_vars.each_line do |line|
      handle_line line, hash
    end
    load hash
    hash
  end

  # Loads environment variables from a file into the `ENV` constant,
  # and skip file reading if missing.
  #
  # ```
  # require "dotenv"
  #
  # File.write ".env-file", "VAR=Hello"
  # Dotenv.load ".env-file" #=> {"VAR" => "Hello"}
  # ```
  def load(filename : Path | String = ".env") : Hash(String, String)
    hash = Hash(String, String).new
    if File.exists?(filename) || File.symlink?(filename)
      File.each_line filename do |line|
        handle_line line, hash
      end
    end
    load hash
    hash
  end

  # Loads environment variables from an `IO` into the `ENV` constant.
  #
  # ```
  # require "dotenv"
  #
  # hash = Dotenv.load IO::Memory.new("VAR=Hello")
  # hash # => {"VAR" => "Hello"}
  # ```
  def load(io : IO) : Hash(String, String)
    hash = Hash(String, String).new
    io.each_line do |line|
      handle_line line, hash
    end
    load hash
    hash
  end

  # Loads a Hash of environment variables into the `ENV` constant.
  #
  # ```
  # require "dotenv"
  #
  # Dotenv.load({"VAR" => "test"})
  # ```
  def load(hash : Hash(String, String)) : Hash(String, String)
    hash.each do |key, value|
      unless ENV.has_key?(key)
        ENV[key] = value
      end
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
