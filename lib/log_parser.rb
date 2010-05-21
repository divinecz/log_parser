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
    raw_data = [parse_raw_data_from_header(header)]
    raw_data += read_raw_data(definition["size"] - 1)
    puts raw_data.size
    { :name => definition["name"] }
  end

  protected

  def load_definitions(definitions_path)
    @definitions = YAML::load(File.read(definitions_path))["logs"]
    raise LogParserException, "Cannot load log definitions from #{definitions_path}" if @definitions.nil?
    #TODO: validate
  end

  def read_byte
    @read_byte_block.call
  end

  def parse_id_from_header(header)
    header & 0x7f
  end

  def parse_raw_data_from_header(header)
    header & 0x80
  end

  def find_definition(id)
    definition = @definitions[id]
    raise LogParserException, "Unknown log definition for 0x#{id.to_s(16)}" if definition.nil?
    definition
  end

  def read_raw_data(size)
    raw_data = []
    size.times do
      raw_data << read_byte
    end
    raw_data
  end

end