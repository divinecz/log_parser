class LogParser

  def initialize(log_definitions_path, &read_byte_block)
    raise ArgumentError, "Missing block" unless block_given?
    load_log_definitions(log_definitions_path)
    @read_byte_block = read_byte_block
  end

  def parse
    header = read_byte
    id = parse_log_id_from_header(header)
    definition = find_log_definition(id)
    data = [parse_log_data_from_header(header)]
    data += read_log_data(definition)
    puts data.size
    { :name => definition["name"] }
  end

  protected

  def load_log_definitions(log_definitions_path)
    @log_definitions = YAML::load(File.read(log_definitions_path))["logs"]
    raise LogParserException, "Cannot load log definitions from #{log_definitions_path}" if @log_definitions.nil?
    #TODO: validate
  end

  def read_byte
    @read_byte_block.call
  end

  def parse_log_id_from_header(header)
    header & 0x7f
  end

  def parse_log_data_from_header(header)
    header & 0x80
  end

  def find_log_definition(log_id)
    log_definition = @log_definitions[log_id]
    raise LogParserException, "Unknown log definition for 0x#{log_id.to_s(16)}" if log_definition.nil?
    log_definition
  end

  def read_log_data(log_definition)
    data = []
    (log_definition["size"] - 1).times do
      data << read_byte
    end
    data
  end

end