module LogParser
  class SDLogParser < Parser

    def initialize(definitions_path)
      @definition_loader = DefinitionLoader.new(definitions_path)
    end

    def parse(data)
      raise LogParserError, "Log size must be 512 bytes." if data.size != 512
      device_id = data[0x1c..0x1d]
      log_id = data[0x1e..0x1f].unpack("S").first
      log_definition = @definition_loader[log_id]
      log = { :name => log_definition.name, :attributes => {} }
      log_definition.attribute_names.each do |attribute_name|
        read = log_definition[attribute_name].read
        type = log_definition[attribute_name].type
        log[:attributes][attribute_name] = parse_attribute(read, data).type_cast(type)
      end
      log
    end

  end
end