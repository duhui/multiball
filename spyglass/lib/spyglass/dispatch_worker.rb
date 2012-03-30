# Worker
# ======
#
module Spyglass
  class DispatchWorker
    include Logging

    WRITE_OPERATIONS=[:set]


    def initialize(socket, writable_pipe, connection = nil)
      @dead_socket, @risen_socket = Socket.pair(:UNIX, :STREAM)      
      fork { PhoenixPatrol.new(@dead_socket).start}
      @socket, @writable_pipe, @redis_config= socket,  writable_pipe, Config.redis_hosts
      @read_read_pipe, @read_write_pipe = IO.pipe
      @read_read2_pipe, @read_write2_pipe = IO.pipe
      @write_read_pipe, @write_write_pipe = IO.pipe
      @write_read2_pipe, @write_write2_pipe = IO.pipe
      @read_worker_pids={}
      @write_worker_pids=[]
      @write_pipes=[]
      spawn_read_workers
      spawn_write_workers
      handle_connection(connection) if connection
      @write_lock = false
    end

    def start
      trap_signals

      loop do
        handle_connection @socket.accept
      end
    end

    def spawn_read_workers 
      @redis_config.each do |redis|
        spawn_read_worker(redis)
      end
    end

    def spawn_read_worker(redis)
        pid = fork { ReadWorker.new(@read_read_pipe, @read_write_pipe, @read_read2_pipe, @read_write2_pipe, redis).start }
        @read_worker_pids[pid] =redis 
    end

    def spawn_write_workers
      @redis_config.each do |redis|
        @write_pipes << IO.pipe 
        @write_worker_pids << fork { WriteWorker.new(@write_pipes.last.first, @write_write_pipe, @write_read2_pipe, @write_write2_pipe, redis).start }
      end
    end

    def handle_connection(conn)
      out "Received connection"
      # This notifies our Master that we have received a connection, expiring
      # it's `IO.select` and preventing it from timing out.
      @writable_pipe.write_nonblock('.')

      #redis=Redis.new(@redis_config)
      # This reads data in from the client connection. We'll read up to 
      # 10000 bytes at the moment.
      data = conn.readpartial(10000)
      @data = data
      array = Marshal.load(data)
      dispatch_command(array.first,data)

      #first element is the command


      #the pools should manage the connection themselves so that when we lock, reads still happen.



      rp = IO.select([@read_read2_pipe, @write_read2_pipe]) #need some improved mechanism?
      rp.each do |r| 
        if r.any?
          conn.write(r[0].readpartial(10000)) 
        end
      end
      #conn.write @read_read2_pipe.readpartial(10000)
      # Since keepalive is not supported we can close the client connection
      # immediately after writing the body.
      conn.close
      out 'Connection closed'

    end

    def write_dispatch(data)
      sleep 1 while @write_lock 
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
      trap(:CHLD) do
        out "CHILD PERISHED!"
        dead_worker, status = Process.wait2
        if status.exitstatus != 0 #he's dead Jim
          if (config = @read_worker_pids.delete(dead_worker))
            out "redispatching, so new worker will pick up."
            read_dispatch(@data) #thinking this means the arg is not necessary, but I wanna be sure. 
                                 #A dispatch is in this case tightly coupled; can't move on until a read has returned successfully and only one read at a time. 
            @risen_socket.write Marshal.dump(config)
          end
        end
      end
      trap(:USR1) do
        puts "Pausing writes."
        @write_lock = true
      end
      trap(:USR2) do
        puts "Resuming writes."
        @write_lock = false
      end

      trap(:USR1) do
        out 'Respawning...' #IT IS RISEN!
        config = Marshal.load(@risen_socket.recv(10000))
        out "#{config} is back online. Spawning..."
        spawn_read_worker(config)
        out "Spawn complete."
      end

      trap(:QUIT) do
        out "Received QUIT"
        exit
      end
    end
  end
end

