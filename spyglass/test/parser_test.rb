require 'stringio'
require "test/unit"
$LOAD_PATH << (File.expand_path(File.dirname(__FILE__))+"/..")

require 'lib/spyglass/redis_parser'

class ParserTest < Test::Unit::TestCase

	def test_chunks
		s = "*2\r\n$3\r\nget\r\n$10\r\nfoobar9996\r\n*3\r\n$3\r\nset\r\n$10\r\nfoobar9998\r\n$13\r\nfoobar9998!!!\r\n*2\r\n$3\r\nget\r\n$10\r\nfoobar9997\r\n*3\r\n$3\r\nset\r\n$10\r\nfoobar9999\r\n$13\r\nfoobar9999!!!\r\n*2\r\n$3\r\nget\r\n$10\r\nfoobar9998\r\n*3\r\n$3\r\nset\r\n$2\r\n*2\r\n$2\r\n*3\r\n"
		sio = StringIO.new(s)
		parser = Object.new
		parser.extend(Spyglass::RedisParser)
		chunk = parser.read_data_chunk(sio)
		assert_equal "*2\r\n$3\r\nget\r\n$10\r\nfoobar9996\r\n", chunk
	end

end