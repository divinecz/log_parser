module LogParser
  class Parser

    def initialize(definitions_path, &read_byte_block)
      raise ArgumentError, "Missing block" unless block_given?
      load_definitions(definitions_path)
      @read_byte_block = read_byte_block
    end

    def parse
      header = read_byte
      id = parse_id_from_header(header)
      definition = find_definition(id)
      raw_data = parse_raw_data_from_header(header)
      raw_data << read_raw_data(definition["size"] - 1)
      attributes = []
      values = []
      definition["attributes"].keys.sort.each do |key|
        attributes << key.to_sym
        values << read_attribute(definition["attributes"][key]["read"].to_s, raw_data).type_cast(definition["attributes"][key]["as"])
      end
      Struct.new(definition["name"].gsub(/(?:^|_)(.)/) { $1.upcase } + "Log", *attributes).new(*values)
    end

    protected

    def load_definitions(definitions_path)
      @definitions = YAML::load(File.read(definitions_path))["logs"]
      raise LogParserException, "Cannot load log definitions from #{definitions_path}" if @definitions.nil?
      #TODO: validate, regexp for read expression
    end

    def read_byte
      @read_byte_block.call
    end

    def parse_id_from_header(header)
      header & 0x7f
    end

    def parse_raw_data_from_header(header)
      (header & 0x80).chr
    end

    def find_definition(id)
      definition = @definitions[id]
      raise LogParserException, "Unknown log definition for 0x#{id.to_s(16)}" if definition.nil?
      definition
    end

    def read_raw_data(size)
      raw_data = ""
      size.times do
        raw_data << read_byte
      end
      raw_data
    end

    def read_attribute(expression, raw_data)
      #TODO: refactoring needed
      data = Attribute.new
      ranges = expression.split(",")
      ranges.each do |range|
        range.strip!
        range_start, range_end = range.split("-")
        # 1 or 1.1
        if range_end.nil?
          byte_position, bit_position = range_start.split(".")
          # 1
          if bit_position.nil?
            data.append_byte(raw_data[byte_position.to_i])
            # 1.1
          else
            data.append_bit(raw_data[byte_position.to_i][bit_position.to_i])
          end
          # 1-2 or 1.1-2.2
        else
        end
      end
      data
    end
  end
end