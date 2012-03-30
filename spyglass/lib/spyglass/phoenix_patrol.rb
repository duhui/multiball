module Spyglass
  class PhoenixPatrol
    include Logging
    include Lockable
    #no need to fork off dispatch but that's what Im doing atm
    def initialize(dead_socket)
      @dead_socket = dead_socket
      @purgatory = []
    end

    def start
      trap_signals
      loop do
        rs = IO.select([@dead_socket], [], [], 10)
        unless rs.nil? || rs.empty?
          data = rs[0][0].recv(10000)
          out "THE DATA #{data.inspect}"
          @purgatory << Marshal.load(data)
          out "SOMEONE HAS GONE DOWN! #{@purgatory.inspect}"
        end
        out "Beginning sweep #{@purgatory.inspect}"
        @purgatory.reject! do |config|
          begin
            @config = config
            @redis=Redis.new(config)
            is_locked?
            #expect the exception.
            out "THIS SERVER IS BACK! LIKE THE MCRIB  #{config}"
            if acquire_lock?
              fork { resurrection_protocol }
              return false
            else
              value= is_locked? #someone is bringing it back, so keep it in purg for now.
              out "WAT? #{value}"
              return value
            end
            Redis.current.quit
            #@dead_socket.puts Marshal.dump(config)
            #Process.kill(:USR1,Process.ppid) #let the parent know to respawn.
            #true
          rescue
            out 'still down'
            false
          ensure
            #
          end
        end
      end
    end

    def resurrection_protocol #do two catchup waits; we want that pause window to be as small as possible.
      @master_config = find_alive_server
      @redis = Redis.new(@config)
      @redis.slaveof @master_config[:host], @master_config[:port]
      until @redis.info['master_sync_in_progress'] == "0" && @redis.info['master_last_io_seconds_ago'] != "-1" #TODO: catch the never connect situation
        out 'Waiting for redis sync to catch up'
        sleep 1
      end
      broadcast 'pause'
      sleep 1 #wait for multicast to propogate
      until @redis.info['master_sync_in_progress'] == "0"
        out 'Waiting for redis sync to catch up'
        sleep 1
      end
      @redis.slaveof "no", "one"
      release_lock
      broadcast 'resume'
      exit
    end

    def find_alive_server
      alive_hosts = Config.redis_hosts.reject do |config|
        begin
          config == @config || @purgatory.include?(config) || Redis.new(config).ping.empty?
        rescue
          false
        ensure
          Redis.current.quit
        end
      end
      if alive_hosts.empty?
        out 'Apparently this cluster is in a failed state.'
        exit 2
      end
      alive_hosts.first
    end

    def broadcast(message)
      socket = UDPSocket.open
      begin
        socket = UDPSocket.open
        socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_TTL, 1)
        socket.send(message, 0, Config.multicast_address, Config.multicast_port)
      ensure
        socket.close
      end
    end


    def trap_signals
      trap(:QUIT) do
        out "Received QUIT"
        exit
      end
    end

  end
end
