module LogParser
  class Reader

    def initialize(block)
      @read_byte_block = block
    end

    def read(size)
      data = ""
      size.times do
        byte = read_byte
        data << byte if byte
      end
      data
    end

    private

    def read_byte
      byte = @read_byte_block.call
      raise LogParserError, "Not a byte value '#{byte.inspect}'" if !byte.nil? && (!byte.is_a?(Fixnum) || !(0..255).include?(byte))
      byte
    end

  end
end