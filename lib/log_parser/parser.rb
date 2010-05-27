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
        raw_data = parse_raw_data_from_header(header)
        raw_data << @reader.read(definition["size"] - 1)
        attributes = []
        values = []
        definition["attributes"].keys.sort.each do |key|
          definition_for_attribute = definition["attributes"][key]
          expression = definition_for_attribute["read"].to_s
          type = definition_for_attribute["type"].downcase.to_sym
          attributes << key.to_sym
          values << read_attribute(expression, raw_data).type_cast(type)
        end
        struct_name = definition["name"].gsub(/(?:^|_)(.)/) { $1.upcase } + "Log"
        struct = Struct.const_defined?(struct_name) ? Struct.const_get(struct_name) : Struct.new(struct_name, *attributes)
        struct.new(*values)
      end
    end

    protected

    def load_definitions(definitions_path)
      @definitions = YAML::load(File.read(definitions_path))["logs"]
      raise LogParserException, "Cannot load log definitions from #{definitions_path}" if @definitions.nil?
      #TODO: validate, regexp for read expression
    end

    def parse_id_from_header(header)
      header & 0x7f
    end

    def parse_raw_data_from_header(header)
      (header & 0x80).chr
    end

    def find_definition(id)
      definition = @definitions[id]
      raise LogParserError, "Unknown log definition for 0x#{id.to_s(16)}" if definition.nil?
      definition
    end

    def read_attribute(expression, raw_data)
      #TODO: refactoring needed
      attribute = Attribute.new
      ranges = expression.split(",")
      ranges.each do |range|
        range.strip!
        range_start, range_end = range.split("-")
        range_start.strip!
        if range_end.nil?
          byte_position, bit_position = range_start.split(".")
          if bit_position.nil?
            attribute.append_byte(raw_data[byte_position.to_i])
          else
            attribute.append_bit(raw_data[byte_position.to_i][bit_position.to_i])
          end
        else
          range_end.strip!
          start_byte_position, start_bit_position = range_start.split(".")
          end_byte_position, end_bit_position = range_end.split(".")
          if start_bit_position.nil?
            start_byte_position.to_i.upto(end_byte_position.to_i) do |i|
              attribute.append_byte(raw_data[i])
            end
          else
            start_byte_position.to_i.upto(end_byte_position.to_i) do |i|
              start_position = i == start_byte_position.to_i ? start_bit_position.to_i : 0
              end_position = i == end_byte_position.to_i ? end_bit_position.to_i : 7
              start_position.upto(end_position) do |j|
                attribute.append_bit(raw_data[i][j])
              end
            end
          end
        end
      end
      attribute
    end
  end
end