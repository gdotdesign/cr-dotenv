module Dotenv
  extend self

  class ParseError < Exception
  end

  # Raises an exception on parsing error.
  class_property strict : Bool = true
  class_property skip_duplicate_keys : Bool = true

  @[Flags]
  private enum Quotes
    Simple
    Double
  end

  private def handle_line(line : String, hash : Hash(String, String))
    return if line.empty?

    reader = Char::Reader.new line

    # Parse variable key
    first_non_blank = true

    key = String.build do |str|
      while reader.has_next?
        case char = reader.current_char
        when .ascii_whitespace?
          reader.next_char
        when '#'
          # The line is a comment, skip it
          return if first_non_blank
          raise ParseError.new "A variable key cannot contain a '#'"
        when '='
          reader.next_char
          break
        else
          first_non_blank = false
          str << char
          reader.next_char
        end
      end
    end

    # Parse variable value
    first = true
    last_whitespace : Char? = nil
    quotes = Quotes::None

    value = String.build do |str|
      while reader.has_next?
        case char = reader.current_char
        when .ascii_whitespace?
          if !quotes.none?
            str << char
          elsif first
            raise ParseError.new("A value cannot start with a whitespace: #{char.inspect}")
          elsif !last_whitespace
            last_whitespace = char
          end
        when '\''
          case quotes
          when .none?
            quotes = Quotes::Simple
          when .simple?
            reader.next_char
            str << char if reader.has_next?
            next
            # Can be the trailing quote
          else
            str << char
          end
        when '"'
          case quotes
          when .none?
            quotes = Quotes::Double
          when .double?
            reader.next_char
            str << char if reader.has_next?
            next
            # Can be the trailing quote
          else
            str << char
          end
        when '#'
          break if quotes.none?
          str << char
        else
          raise ParseError.new("An unquoted value cannot contain a whitespace: #{last_whitespace.inspect}") if last_whitespace
          first = false
          str << char
        end
        reader.next_char
      end
    end

    hash[key] = value
  rescue ex
    raise ParseError.new("Parse error on line: `#{line}`", cause: ex) if @@strict
  end

  # Loads environment variables from a `String` into the `ENV` constant.
  #
  # ```
  # require "dotenv"
  #
  # hash = Dotenv.load_string "VAR=Hello"
  # hash # => {"VAR" => "Hello"}
  # ```
  def load_string(env_vars : String) : Hash(String, String)
    hash = Hash(String, String).new
    env_vars.each_line do |line|
      handle_line line, hash
    end
    load hash
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
  def load?(filename : Path | String = ".env") : Hash(String, String)?
    if File.exists?(filename) || File.symlink?(filename)
      load filename
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
  def load(filename : Path | String = ".env") : Hash(String, String)
    hash = Hash(String, String).new
    File.each_line filename do |line|
      handle_line line, hash
    end
    load hash
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
      unless ENV.has_key?(key) && skip_duplicate_keys
        ENV[key] = value
      end
    end
    hash
  end

  # Allows for overriding existing `ENV` keys. See `load`.
  #
  # ```
  # require "dotenv"
  #
  # Dotenv.load ".env"       # => {"VAR" => "Hello"}
  # Dotenv.load! ".env.test" # => {"VAR" => "World"}
  # ```
  def load!(filename : Path | String = ".env") : Hash(String, String)
    load_with_temp_override do
      load filename
    end
  end

  # Allows for overriding existing `ENV` keys. See `load`.
  #
  # ```
  # require "dotenv"
  #
  # Dotenv.load IO::Memory.new("VAR=Hello")  # => {"VAR" => "Hello"}
  # Dotenv.load! IO::Memory.new("VAR=World") # => {"VAR" => "World"}
  # ```
  def load!(io : IO) : Hash(String, String)
    load_with_temp_override do
      load io
    end
  end

  # Allows for overriding existing `ENV` keys. See `load`.
  #
  # ```
  # require "dotenv"
  #
  # Dotenv.load({"VAR" => "Hello"})  # => ENV["VAR"] == "Hello"
  # Dotenv.load!({"VAR" => "World"}) # => ENV["VAR"] == "World"
  # ```
  def load!(hash : Hash(String, String)) : Hash(String, String)
    load_with_temp_override do
      load hash
    end
  end

  # Allows duplicate `ENV` keys to be overriden. Lock is placed back
  # on after block finshes. returns the loaded env keys.
  #
  # ```
  # require "dotenv"
  #
  # Dotenv.load_with_temp_override do
  #   Dotenv.load({"VAR" => "test"})
  # end
  # ```
  def load_with_temp_override : Hash(String, String)
    self.skip_duplicate_keys = false
    hash = yield
    self.skip_duplicate_keys = true
    hash
  end
end
