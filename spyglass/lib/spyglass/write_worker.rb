# Worker
# ======
#
module Spyglass
  class WriteWorker
    include Logging


    def initialize(write_read_pipe, write_write_pipe, write_read2_pipe, write_write2_pipe, redis_config)
      @write_read_pipe, @write_write_pipe, @write_read2_pipe, @write_write2_pipe, @redis_config = write_read_pipe, write_write_pipe, write_read2_pipe, write_write2_pipe, redis_config
      @redis = Redis.new(redis_config)
    end

    def start
      trap_signals

      loop do
        while(data = @write_read_pipe.readpartial(10000)) do
          out "WE GET SIGNAL! #{Process.pid}"
          array = Marshal.load(data)
          result = dispatch(array)
          out "RESULT! #{result}"
          @write_write2_pipe.write Marshal.dump(result)
        end
      end
    end

    def dispatch(array)
      @redis.send(array.shift, *array)
    end

    def trap_signals
      trap(:QUIT) do
        out "Received QUIT"
        exit
      end
    end
  end
end
