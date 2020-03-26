module Dotenv
  module Parser
    @current_char : Char
    @column_number = 0
    @end_of_file = false

    class Error < Exception
    end

    def self.new(data : IO)
      IOParser.new data
    end

    def self.new(data : String)
      StringParser.new data
    end

    # Raises an exception on parsing error.
    class_property strict : Bool = true

    abstract def next_char : Char

    def parse : Hash(String, String)
      hash = Hash(String, String).new
      line_number = 1
      while !@end_of_file
        begin
          if key = parse_key
            value = parse_value
            hash[key] = value
          end
        rescue ex
          raise Error.new(
            "Parse error#{" on value of variable key `" + key + '`' if key} on line #{line_number}:#{@column_number}",
            cause: ex
          ) if Parser.strict
        end
        line_number += 1
      end

      hash
    end

    private def skip_comment
      loop do
        case @current_char
        when '\n', '\0' then break
        else                 next_char
        end
      end
      next_char
    end

    private def parse_key : String?
      @column_number = 0
      # Parse variable key
      first_non_blank = false

      key = String.build do |str|
        loop do
          case @current_char
          when '\0'
            @end_of_file = true
            break
          when '='
            next_char
            break
          when '\n'
            break
          when .ascii_whitespace?
            # Raises if not a leading space
            raise Error.new("A variable key cannot contain a whitespace: #{@current_char.inspect}") if first_non_blank
          when '#'
            if first_non_blank
              raise Error.new("Invalid character in variable key: '#'")
            else
              # The line is a comment, skip it
              skip_comment
              break
            end
          when '\'', '"'
            raise Error.new("Invalid character in variable key: #{@current_char.inspect}")
          else
            first_non_blank = true
            str << @current_char
          end
          next_char
        end
      end
      # Returns on empty lines
      if key.empty?
        next_char if @current_char == '\n'
        return
      elsif @current_char == '\0' || @current_char == '\n'
        raise Error.new("Unexpected end of line: no value for variable key '#{key}'")
      end

      key
    end

    private def parse_value : String
      # Parse variable value
      first = true
      last_whitespace : Char? = nil
      quotes = Quotes::None

      value = String.build do |str|
        loop do
          case @current_char
          when '\0'
            @end_of_file = true
            break
          when '\n'
            break
          when .ascii_whitespace?
            if !quotes.none?
              str << @current_char
            elsif first
              raise Error.new("A value cannot start with a whitespace: #{@current_char.inspect}")
            elsif !last_whitespace
              last_whitespace = @current_char
            end
          when '\''
            case quotes
            when .none?
              quotes = Quotes::Simple
            when .simple?
              quotes = Quotes::None
            else
              str << @current_char
            end
          when '"'
            case quotes
            when .none?
              quotes = Quotes::Double
            when .double?
              quotes = Quotes::None
            else
              str << @current_char
            end
          when '#'
            if quotes.none?
              str << @current_char
            elsif last_whitespace
              skip_comment
              break
            else
              first = false
              last_whitespace = nil
              str << @current_char
            end
          else
            raise Error.new("An unquoted value cannot contain a whitespace: #{last_whitespace.inspect}") if last_whitespace
            first = false
            last_whitespace = nil
            str << @current_char
          end
          next_char
        end
      end

      case quotes
      when .simple? then raise Error.new("Unterminated simple quote")
      when .double? then raise Error.new("Unterminated double quotes")
      else
        # ok
      end

      value
    end
  end

  private struct IOParser
    include Parser

    def initialize(@io : IO)
      @current_char = @io.read_char || '\0'
    end

    def next_char : Char
      @column_number += 1
      @current_char = @io.read_char || '\0'
    end
  end

  private struct StringParser
    include Parser

    def initialize(data : String)
      @reader = Char::Reader.new data
      @current_char = @reader.current_char
    end

    def next_char : Char
      @column_number += 1
      @current_char = @reader.next_char
    end
  end
end
