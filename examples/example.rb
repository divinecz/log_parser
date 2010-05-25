require File.dirname(__FILE__) + "/../log_parser"
require "stringio"

LOG_DEFINITIONS_PATH = File.dirname(File.expand_path(__FILE__)) + "/log_definitions.yml"

HEX_LOGS = {
  :log_create_account => "CCD0430CE80AFFFF",
  :log_change_account => "4C976B0CE80A0000"
}

def hex_log_to_binary(hex_log)
  StringIO.new(hex_log.to_a.pack("H*"))
end

binary_logs = {}
HEX_LOGS.each_pair do |key, value|
  binary_logs[key] = hex_log_to_binary(value)
end

log = binary_logs[:log_create_account]

log_parser = LogParser.new(LOG_DEFINITIONS_PATH) do
  log.readbyte
end

puts log_parser.parse.inspect