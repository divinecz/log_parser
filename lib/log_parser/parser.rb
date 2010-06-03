module LogParser
  class Parser

    def initialize
      raise NotImplementedError
    end

    protected

    def parse_attribute(read, data)
      attribute = Attribute.new
      ranges = read.split(",")
      ranges.each do |range|
        range_start, range_end = range.split("-")
        if range_end.nil?
          parse_attribute_part(attribute, data, range_start)
        else
          parse_attribute_part_range(attribute, data, range_start, range_end)
        end
      end
      attribute
    end

    def parse_attribute_part(attribute, data, index)
      byte_index, bit_index = index.split(".")
      byte_index = byte_index.to_i
      if bit_index.nil?
        attribute.append_byte(data[byte_index])
      else
        bit_index = bit_index.to_i
        attribute.append_bit(data[byte_index][bit_index])
      end
    end

    def parse_attribute_part_range(attribute, data, start_index, end_index)
      start_byte_index, start_bit_index = start_index.split(".")
      end_byte_index, end_bit_index = end_index.split(".")
      start_byte_index = start_byte_index.to_i
      end_byte_index = end_byte_index.to_i
      if start_bit_index.nil?
        start_byte_index.upto(end_byte_index) do |byte_index|
          attribute.append_byte(data[byte_index])
        end
      else
        start_bit_index = start_bit_index.to_i
        end_bit_index = end_bit_index.to_i
        start_byte_index.upto(end_byte_index) do |byte_index|
          current_bit_start_index = byte_index == start_byte_index ? start_bit_index : 0
          current_bit_end_index = byte_index == end_byte_index ? end_bit_index : 7
          current_bit_start_index.upto(current_bit_end_index) do |bit_index|
            attribute.append_bit(data[byte_index][bit_index])
          end
        end
      end
    end

  end
end