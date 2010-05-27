module LogParser
  class Attribute

    def initialize
      @position = 0
      @buffer = ""
    end

    def append_bit(bit)
      raise "Not a bit value '#{bit.inspect}'" if !bit.is_a?(Fixnum) || !(0..1).include?(bit)
      if @position % 8 == 0
        @buffer << "\0"
      end
      if bit == 1
        @buffer[@position / 8] |= (0x1 << (@position % 8))
      end
      @position += 1
    end

    def append_byte(byte)
      raise "Not a byte value '#{byte.inspect}'" if !byte.is_a?(Fixnum) || !(0..255).include?(byte)
      if @position % 8 == 0
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
      case type
      when "bool"
        @buffer.unpack({1 => "C", 2 => "v", 4 => "L"}[@buffer.size]).first > 0
      when "uint"
        @buffer << "\0" if @buffer.size == 3
        @buffer.unpack({1 => "C", 2 => "v", 4 => "L"}[@buffer.size]).first
      end
    end

  end
end