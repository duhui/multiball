# Worker
# ======
#
module Spyglass
  class ReadWorker
    include Logging
    include Lockable


    def initialize(read_read_pipe, read_write_pipe, read_read2_pipe, read_write2_pipe, redis_config)
      @read_read_pipe, @read_write_pipe, @read_read2_pipe, @read_write2_pipe, @redis_config = read_read_pipe, read_write_pipe, read_read2_pipe, read_write2_pipe, redis_config
      @redis = Redis.new(redis_config)
      exit if is_locked?
      out "SPAWN READ WORKER: #{Process.ppid} - #{Process.pid} - #{redis_config}"
    end

    def start
      trap_signals

      loop do
        while(data = @read_read_pipe.readpartial(10000)) do
          array = Marshal.load(data)
          result = dispatch(array)
          @read_write2_pipe.write Marshal.dump(result)
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

