$:.unshift File.dirname($0) + "/../lib"
require "log_parser"
require "stringio"

LOGS_PATH = File.dirname(File.expand_path(__FILE__)) + "/logs.yml"

HEX_LOGS = {
  :log_create_account => "CCD0430CE80AFFFF",
  :log_change_account => "4C976B0CE80A0000"
}

def hex_log_to_binary(hex_log)
  StringIO.new([hex_log].pack("H*"))
end

binary_log = hex_log_to_binary(HEX_LOGS.values.join)

log_parser = LogParser::UniLogParser.new(LOGS_PATH) do
  begin
    binary_log.readbyte 
  rescue EOFError
    nil
  end
end

while parsed_log = log_parser.parse do
  puts parsed_log.inspect
end