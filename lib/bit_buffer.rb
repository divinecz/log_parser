#TODO: namespaces
class BitBuffer

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
    8.times do |i|
      append_bit(byte[i])
    end
  end

  def to_s
    @buffer
  end

end