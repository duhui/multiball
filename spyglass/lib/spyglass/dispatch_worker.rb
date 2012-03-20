# Worker
# ======
#
module Spyglass
  class DispatchWorker
    include Logging

    WRITE_OPERATIONS=[:set]


    def initialize(socket, writable_pipe, redis_config, connection = nil)
      @socket, @writable_pipe, @redis_config= socket,  writable_pipe, redis_config
      @read_read_pipe, @read_write_pipe = IO.pipe
      @read_read2_pipe, @read_write2_pipe = IO.pipe
      @write_read_pipe, @write_write_pipe = IO.pipe
      @write_read2_pipe, @write_write2_pipe = IO.pipe
      @read_worker_pids=[]
      @write_worker_pids=[]
      @write_pipes=[]
      spawn_read_workers
      spawn_write_workers
      handle_connection(connection) if connection
    end

    def start
      trap_signals

      loop do
        handle_connection @socket.accept
      end
    end

    def spawn_read_workers
      3.times do 
        @read_worker_pids << fork { ReadWorker.new(@read_read_pipe, @read_write_pipe, @read_read2_pipe, @read_write2_pipe, @redis_config).start }
      end
    end

    def spawn_write_workers
      3.times do
        @write_pipes << IO.pipe 
        @write_worker_pids << fork { WriteWorker.new(@write_pipes.last.first, @write_write_pipe, @write_read2_pipe, @write_write2_pipe, @redis_config).start }
      end
    end

    def handle_connection(conn)
        verbose "Received connection"
      # This notifies our Master that we have received a connection, expiring
      # it's `IO.select` and preventing it from timing out.
      @writable_pipe.write_nonblock('.')

      #redis=Redis.new(@redis_config)
      out 'PREPARE THE READ'
      # This reads data in from the client connection. We'll read up to 
      # 10000 bytes at the moment.
      data = conn.readpartial(10000)
      array = Marshal.load(data)
      dispatch_command(array.first,data)

      #first element is the command

      rp = IO.select([@read_read2_pipe, @write_read2_pipe]) #need some improved mechanism?
      rp.each{|r| conn.write(r[0].readpartial(10000)) if r.any? }
      #conn.write @read_read2_pipe.readpartial(10000)
      out "WRITE COMPLETE"
      # Since keepalive is not supported we can close the client connection
      # immediately after writing the body.
      conn.close

      out "Closed connection"
    end

    def write_dispatch(data)
      p 'writing data!'
      @write_pipes.each do |pipe_pair|
        pipe_pair.last.write data
      end
      #@write_write_pipe
    end

    def read_dispatch(data)
      @read_write_pipe.write data
    end

    def dispatch_command(command,data)
      (WRITE_OPERATIONS.include?(command) ? write_dispatch(data) : read_dispatch(data))
    end

    def trap_signals
      trap(:QUIT) do
        out "Received QUIT"
        exit
      end
    end
  end
end
