module LogParser
  class Parser

    def initialize(definitions_path, &read_byte_block)
      raise ArgumentError, "Missing block" unless block_given?
      load_definitions(definitions_path)
      @reader = Reader.new(read_byte_block)
    end

    def parse
      header = @reader.read(1)[0]
      if header
        id = parse_id_from_header(header)
        definition = find_definition(id)
        data = parse_data_from_header(header)
        data << @reader.read(definition["size"] - 1)
        attributes = []
        values = []
        definition["attributes"].keys.sort.each do |key|
          definition_for_attribute = definition["attributes"][key]
          expression = definition_for_attribute["read"].to_s
          type = definition_for_attribute["type"].downcase.to_sym
          attributes << key.to_sym
          values << parse_attribute(expression, data).type_cast(type)
        end
        struct_name = definition["name"].gsub(/(?:^|_)(.)/) { $1.upcase } + "Log"
        struct = Struct.const_defined?(struct_name) ? Struct.const_get(struct_name) : Struct.new(struct_name, *attributes)
        struct.new(*values)
      end
    end

    private

    def load_definitions(definitions_path)
      @definitions = YAML::load(File.read(definitions_path))["logs"]
      raise LogParserException, "Cannot load log definitions from #{definitions_path}" if @definitions.nil?
    end

    def parse_id_from_header(header)
      header & 0x7f
    end

    def parse_data_from_header(header)
      (header & 0x80).chr
    end

    def find_definition(id)
      definition = @definitions[id]
      raise LogParserError, "Unknown log definition for 0x#{id.to_s(16)}" if definition.nil?
      definition
    end

    def parse_attribute(expression, data)
      attribute = Attribute.new
      ranges = expression.split(",")
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