# Worker
# ======
#
module Spyglass
  class DispatchWorker
    include Logging
    include RedisParser

    COMMAND_DELIMITER = "\r\n"

    WRITE_OPERATIONS=[:set]


    def initialize(socket, writable_pipe, dead_write, connection = nil)
      @socket, @writable_pipe, @redis_config= socket,  writable_pipe, Config.redis_hosts
      @dead_write = dead_write
      @read_read_pipe, @read_write_pipe = IO.pipe
      @read_read2_pipe, @read_write2_pipe = IO.pipe
      @write_read_pipe, @write_write_pipe = IO.pipe
      @write_read2_pipe, @write_write2_pipe = IO.pipe
      @read_worker_pids={}
      @write_worker_pids={}
      @write_query_pipes=[]
      @write_response_pipes=[]
      spawn_read_workers
      spawn_write_workers
      handle_connection(connection) if connection
      @write_lock = false
    end

    def start
      trap_signals

      loop do
        out 'looping!'
        handle_connection @socket.accept
        out 'done'
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
        @write_query_pipes << IO.pipe
        write_response_pipe=IO.pipe
        pid = fork { WriteWorker.new(@write_query_pipes.last.first, write_response_pipe.last, redis).start }
        @write_response_pipes << write_response_pipe.first
        @write_worker_pids[pid] = redis
      end
    end

    def handle_connection(conn)
      out "Received connection"
      begin
        while(rs = IO.select([conn], [], [], 5))
        
      # This notifies our Master that we have received a connection, expiring
      # it's `IO.select` and preventing it from timing out.
      @writable_pipe.write_nonblock('.')

      #redis=Redis.new(@redis_config)
      # This reads data in from the client connection. We'll read up to
      # 10000 bytes at the moment.

        data = read_data_chunk(conn)
        if data.nil? || data.empty?
          next
        end
        @data = parse_data_stream(data)
        dispatch_command(@data.first,data)

        #first element is the command

        #the pools should manage the connection themselves so that when we lock, reads still happen.
        rp = IO.select([@read_read2_pipe, *@write_response_pipes]) #need some improved mechanism?
        rp.each do |r|
          if r.any?  
            res=r[0].readpartial(10000)
            #res.
            conn.write(res)
          end
        end
        #conn.write @read_read2_pipe.readpartial(10000)
        # Since keepalive is not supported we can close the client connection
        # immediately after writing the body.
        out 'process complete'
        #conn.close
      end
     #   out 'Connection closed'
      rescue Errno::EPIPE
        out 'Communication between dispatch and workers seems hosed. Committing seppuku.'
      rescue Exception => e 
        out "Incoming data unprocessable: #{data} with #{e.backtrace}"
        #swallow...may have closed client side etc.
      end

    end

    def write_dispatch(data)
      sleep 1 while @write_lock
      @write_query_pipes.each do |pipe_pair|
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

    #TODO: Pull out to module
    def parse_data_stream(data)
      out "COMMAND DELIMITED! #{data}"
      data_array=data.split(COMMAND_DELIMITER)

      data_array=data.split(COMMAND_DELIMITER).drop(1).each_slice(2).collect{|i| i.last}
      data_array[0] = data_array.first.to_sym
      data_array
    end

    def trap_signals
      trap(:CHLD) do
        out "CHILD PERISHED!"
        dead_worker, status = Process.wait2
        if status.exitstatus != 0 #he's dead Jim
          if (config = @read_worker_pids.delete(dead_worker))
            out "Dead guy was #{dead_worker} with #{config} - redispatching, so new worker will pick up."
            read_dispatch(@data) #thinking this means the arg is not necessary, but I wanna be sure.
            #A dispatch is in this case tightly coupled; can't move on until a read has returned successfully and only one read at a time.
            @dead_write.write Marshal.dump(config)
          elsif (config = @write_worker_pids[dead_worker])
            @dead_write.write Marshal.dump(config)
          end
        end
      end
      trap(:USR1) do
        puts "Pausing writes."
        @write_lock = true
      end

      trap(:USR2) do
        out 'Respawning...' #IT IS RISEN!
        @read_worker_pids.keys.each do |pid|
          Process.kill(:HUP, pid)
          dead_worker, status = Process.waitpid2(pid)
        end
        @read_worker_pids={}
        spawn_read_workers
        @write_worker_pids.each do |pid|
          Process.kill(:HUP, pid)
          dead_worker, status = Process.waitpid2(pid)
        end
        @write_query_pipes = []
        @write_worker_pids={}
        spawn_write_workers
        out "ReSpawn complete."
        @write_lock = false
      end

      trap(:QUIT) do
        out "Received QUIT"
        exit
      end
    end
  end
end
