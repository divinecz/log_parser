module LogParser
  class LogDefinition

    attr_reader :id, :name, :size, :attribute_names

    def initialize(id, name, size, attribute_definitions)
      @id = id.to_i
      raise LogParserError, "Invalid log id '#{id.to_s(16)}'" if !(0x1..0x7f).include?(id)
      @name = name
      raise LogParserError, "Name is not defined for log 0x#{id.to_s(16)}" if name.strip.empty?
      @size = size.to_i
      raise LogParserError, "Size is not defined for log 0x#{id.to_s(16)}" if size < 1
      @attribute_names = attribute_definitions.keys.sort.collect{ |key| key.to_sym }
      @attribute_definitions = {}
      attribute_definitions.each_pair do |key, value|
        @attribute_definitions[key.to_sym] = AttributeDefinition.new(key, value["read"], value["type"])
      end
    end

    def [](attribute_name)
      @attribute_definitions[attribute_name]
    end

  end
end