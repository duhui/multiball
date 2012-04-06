# Worker
# ======
#
module Spyglass
  class WriteWorker
    include Logging
    include Lockable


    def initialize(write_read_pipe, write_write2_pipe, redis_config)
      @write_read_pipe, @write_write2_pipe, @redis_config = write_read_pipe, write_write2_pipe, redis_config
      @redis = Redis.new(redis_config)
      exit if is_locked?
    end

    def start
      trap_signals

      loop do
        while(data = @write_read_pipe.readpartial(10000)) do
          array = data #Marshal.load(data)
          result = dispatch(array)
          @write_write2_pipe.write result
        end
      end
    end

    def dispatch(array)
      @redis.client.connection.instance_variable_get("@sock").write(array)
      @redis.client.connection.instance_variable_get("@sock").recv(10000)
    end

    def trap_signals
      trap(:QUIT) do
        out "Received QUIT"
        exit
      end
    end
  end
end
