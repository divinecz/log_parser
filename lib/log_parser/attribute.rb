module LogParser
  class Attribute

    def initialize
      @position = 0
      @buffer = ""
    end

    def append_bit(bit)
      raise "Not a bit value '#{bit.inspect}'" if !bit.is_a?(Fixnum) || !(0..1).include?(bit)
      if current_byte_position == 0
        @buffer << "\0"
      end
      if bit == 1
        @buffer[@position / 8] |= (0x1 << (current_byte_position))
      end
      @position += 1
    end

    def append_byte(byte)
      raise "Not a byte value '#{byte.inspect}'" if !byte.is_a?(Fixnum) || !(0..255).include?(byte)
      if current_byte_position == 0
        @buffer << byte
      else
        8.times do |i|
          append_bit(byte[i])
        end
      end
    end

    def to_s
      @buffer
    end

    def type_cast(type)
      if @buffer.any?
        case type
        when :bcd
          type_cast_bcd
        when :bool
          type_cast_uint > 0
        when :string
          Iconv.iconv("UTF8", "CP1250", @buffer).first
        when :uint
          type_cast_uint
        else
          raise LogParserError, "Unknown type '#{type}'"
        end
      end
    end

    private

    def current_byte_position
      @position % 8
    end

    def type_cast_bcd
      buffer = @buffer
      number = 0
      buffer.each_with_index do |char, index|
        digits = buffer.unpack("C").first
        number = ((digits & 0x0f) * (index + 1)) + ((digits >> 4)  * 10 * (index + 1))
      end
      number
    end

    def type_cast_uint
      buffer = @buffer
      while buffer.size > 2 && buffer.size < 8 && (buffer.size != 4 || buffer.size != 8) do
        buffer << "\0"
      end
      buffer.unpack({1 => "C", 2 => "S", 4 => "L", 8 => "Q"}[buffer.size]).first
    end

  end
end