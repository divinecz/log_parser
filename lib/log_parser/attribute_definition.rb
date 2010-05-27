module LogParser
  class AttributeDefinition

    attr_reader :name, :read, :type

    def initialize(name, read, type)
      @name = name
      @read = read.to_s.strip
      raise LogParserError, "Read is not defined for attribute '#{@name}'" if @read.empty?
      @type = type.to_s
      raise LogParserError, "Type is not defined for attribute '#{@name}'" if @type.empty?
      @type = @type.to_sym
    end

  end
end