module LogParser
  class DefinitionLoader

    def initialize(definitions_path)
      definitions = YAML::load(File.read(definitions_path))["logs"]
      raise LogParserException, "Cannot load log definitions from #{definitions_path}" if definitions.nil?
      @definitions = []
      definitions.each_pair do |key, value|
        @definitions[key] = LogDefinition.new(key, value["name"], value["size"], value["attributes"])
      end
    end

    def [](id)
      definition = @definitions[id]
      raise LogParserError, "Unknown log definition for 0x#{id.to_s(16)}" if definition.nil?
      definition
    end

  end
end