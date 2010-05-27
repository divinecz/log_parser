module LogParser
  class Parser

    def initialize(definitions_path, &read_byte_block)
      raise ArgumentError, "Missing block" unless block_given?
      @definition_loader = DefinitionLoader.new(definitions_path)
      @reader = Reader.new(read_byte_block)
    end

    def parse
      header = @reader.read(1)[0]
      if header
        id = parse_id_from_header(header)
        log_definition = @definition_loader[id]
        data = parse_data_from_header(header)
        data << @reader.read(log_definition.size - 1)
        attribute_values = []
        log_definition.attribute_names.each do |attribute_name|
          read = log_definition[attribute_name].read
          type = log_definition[attribute_name].type
          attribute_values << parse_attribute(read, data).type_cast(type)
        end
        struct_name = log_definition.name.gsub(/(?:^|_)(.)/) { $1.upcase } + "Log"
        if Struct.const_defined?(struct_name)
          Struct.const_get(struct_name)
        else
          Struct.new(struct_name, *log_definition.attribute_names)
        end.new(*attribute_values)
      end
    end

    private

    def parse_id_from_header(header)
      header & 0x7f
    end

    def parse_data_from_header(header)
      (header & 0x80).chr
    end

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