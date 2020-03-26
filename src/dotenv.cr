require "./parser"

module Dotenv
  @[Flags]
  enum Quotes
    Simple
    Double
  end

  class BuildError < Exception
  end

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

  # Builds a `.env` formatted string, and escape special characters in values.
  #
  # Only variable key characters are validated.
  #
  # ```
  # require "dotenv"
  #
  # Dotenv.build({"VAR" => "Hello"}) => "VAR=Hello"
  # ```
  def build(env_vars : Hash(String, String), value_quotes : Quotes = Quotes::None) : String
    String.build { |str| build str, env_vars, value_quotes }
  end

  # Builds a `.env` formatted data to the `IO`, and quotes to put around the value.
  #
  # Only variable key characters are validated.
  #
  # ```
  # require "dotenv"
  #
  # File.open "w", ".env" do |io|
  #   Dotenv.build(io, {"VAR" => "Hello"})
  # end
  # ```
  def build(io, env_vars : Hash(String, String), value_quotes : Quotes = Quotes::None) : Nil
    line_number = 1
    env_vars.each do |variable, value|
      column_number = 0
      variable.each_char do |char|
        case char
        when .ascii_whitespace?, '#', '\\', '"', '\'', '\n', '='
          raise BuildError.new("Invalid character in variable key at line #{line_number}:#{column_number}: #{char.inspect}")
        else
          io << char
          column_number += 1
        end
      end
      io << '='
      case value_quotes
      when .simple? then io << '\'' << value << '\''
      when .double? then io << '"' << value << '"'
      else               io << value
      end
      io << '\n'
      line_number += 1
    end
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
  # Dotenv.load ".absent-file" # => No such file or directory (File::NotFoundError)
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
