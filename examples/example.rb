$:.unshift File.dirname($0) + "/../lib"
require "log_parser"
require "stringio"

LOGS_PATH = File.dirname(File.expand_path(__FILE__)) + "/logs.yml"

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

log_parser = LogParser::Parser.new(LOGS_PATH) do
  log.readbyte
end

parsed_log = log_parser.parse
puts parsed_log.members
puts parsed_log.inspect