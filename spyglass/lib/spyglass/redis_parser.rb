module Spyglass
  module RedisParser

	ARGUMENT = /\$([0-9]+)\r\n/
	NO_OF_ARGUMENTS = /\*([0-9]+)\r\n/

    def read_data_chunk(io)
      data = ""
      header = parse_num_args(io)
      data << header.last
      header.first.times do
        data << parse_for_(io)
      end
      return data
    end

    def parse_num_args(io)
    	data = parse_for_(io, true)
    	[data.gsub(NO_OF_ARGUMENTS, '\\1').to_i, data]
    end

    def parse_for_(io, no_arg_mode=false)
      regex = (no_arg_mode ? NO_OF_ARGUMENTS : ARGUMENT )
      datastream=""
      while(char = io.read(1))
        datastream << char
        if char == "\n" #we've reached the end of the byte length
          byte_no = datastream.gsub(regex, '\\1')
          datastream << io.read(byte_no.to_i+2) unless no_arg_mode
          break
        end
      end
      return datastream
    end
  end
end
