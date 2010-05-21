class LogParser

  def initialize(definitions_path, &read_byte_block)
    raise ArgumentError, "Missing block" unless block_given?
    load_definitions(definitions_path)
    @read_byte_block = read_byte_block
  end

  def parse
    header = read_byte
    id = parse_id_from_header(header)
    definition = find_definition(id)
    puts definition.inspect
    raw_data = parse_raw_data_from_header(header)
    raw_data << read_raw_data(definition["size"] - 1)
    attributes = {}
    definition["attributes"].each_pair do |key, value|
      puts key
      attributes[key.to_sym] = type_cast_data(read_data(value["read"].to_s, raw_data), value["as"])
    end
    { :name => definition["name"], :attributes => attributes }
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
  
  def read_data(expression, raw_data)
    data = ""
    ranges = expression.split(",")
    ranges.each do |range|
      range.strip!
      range_start, range_end = range.split("-")
      # 1 or 1.1
      if range_end.nil?
        byte_position, bit_position = range_start.split(".")
        # 1
        if bit_position.nil?
          data << raw_data[byte_position.to_i]
        # 1.1
        else
          byte = raw_data[byte_position.to_i]
          data = ((byte >> (7 - bit_position.to_i)) & 0x1).chr
        end
      # 1-2 or 1.1-2.2
      else
      end
    end
    data
  end
  
  def type_cast_data(data, as)
    size = data.size
    case as
    when "bool"
      data.unpack({1 => "C", 2 => "v", 4 => "I"}[size]).first > 0
    when "uint"
      data.unpack({1 => "C", 2 => "v", 4 => "I"}[size]).first
    end
  end
  
end