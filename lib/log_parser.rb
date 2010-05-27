require "yaml"
require "log_parser/attribute"
require "log_parser/parser"
require "log_parser/reader"

module LogParser
  class LogParserError < StandardError; end
end