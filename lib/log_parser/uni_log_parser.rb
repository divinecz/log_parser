module LogParser
  class UniLogParser < Parser

    def initialize(definitions_path, &read_byte_block)
      raise ArgumentError, "Missing block" unless block_given?
      @definition_loader = DefinitionLoader.new(definitions_path)
      @reader = Reader.new(read_byte_block)
    end

    def parse
      header = @reader.read(1)[0].try(:ord)
      if header
        id = parse_id_from_header(header)
        log_definition = @definition_loader[id]
        data = parse_data_from_header(header)
        data << @reader.read(log_definition.size - 1)
        log = { :name => log_definition.name, :attributes => {} }
        log_definition.attribute_names.each do |attribute_name|
          read = log_definition[attribute_name].read
          type = log_definition[attribute_name].type
          log[:attributes][attribute_name] = parse_attribute(read, data).type_cast(type)
        end
        log
      end
    end

    private

    def parse_id_from_header(header)
      header & 0x7f
    end

    def parse_data_from_header(header)
      (header & 0x80).chr
    end

  end
end