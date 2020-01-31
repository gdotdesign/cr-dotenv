require "./parser"

module Dotenv
  extend self

  # Parses a `.env` formatted `String`/`IO` data, and returns a hash (without loading it to `ENV`).
  #
  # ```
  # require "dotenv"
  #
  # hash = Dotenv.parse "VAR=Hello"
  # hash # => {"VAR" => "Hello"}
  # ```
  def parse(env_vars : String | IO) : Hash(String, String)
    Parser.new(env_vars).parse
  end

  # Loads environment variables from a `String` into the `ENV` constant.
  #
  # ```
  # require "dotenv"
  #
  # hash = Dotenv.load_string "VAR=Hello"
  # hash # => {"VAR" => "Hello"}
  # ```
  def load_string(env_vars : String, override_keys : Bool = false) : Hash(String, String)
    load parse(env_vars), override_keys
  end

  # Loads environment variables from a file into the `ENV` constant
  # if the file is present, else returns `nil`.
  #
  # ```
  # require "dotenv"
  #
  # File.write ".env-file", "VAR=Hello"
  # Dotenv.load? ".env-file"    # => {"VAR" => "Hello"}
  # Dotenv.load? ".not-present" # => nil
  # ```
  def load?(filename : Path | String = ".env", override_keys : Bool = false) : Hash(String, String)?
    if File.exists?(filename) || File.symlink?(filename)
      load filename, override_keys
    end
  end

  # Loads environment variables from a file into the `ENV` constant.
  #
  # ```
  # require "dotenv"
  #
  # File.write ".env-file", "VAR=Hello"
  # Dotenv.load ".env-file"    # => {"VAR" => "Hello"}
  # Dotenv.load ".absent-file" # => No such file or directory (Errno)
  # ```
  def load(filename : Path | String = ".env", override_keys : Bool = false) : Hash(String, String)
    hash = File.open filename do |file|
      parse file
    end
    load hash, override_keys
  end

  # Loads environment variables from an `IO` into the `ENV` constant.
  #
  # ```
  # require "dotenv"
  #
  # hash = Dotenv.load IO::Memory.new("VAR=Hello")
  # hash # => {"VAR" => "Hello"}
  # ```
  def load(io : IO, override_keys : Bool = false) : Hash(String, String)
    load parse(io), override_keys
  end

  # Loads a Hash of environment variables into the `ENV` constant.
  #
  # ```
  # require "dotenv"
  #
  # Dotenv.load({"VAR" => "test"})
  # ```
  def load(hash : Hash(String, String), override_keys : Bool = false) : Hash(String, String)
    hash.each do |key, value|
      unless ENV.has_key?(key) && !override_keys
        ENV[key] = value
      end
    end
    hash
  end
end
