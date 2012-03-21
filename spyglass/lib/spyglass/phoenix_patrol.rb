module Spyglass
  class PhoenixPatrol
    include Logging
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
        @purgatory.reject! do |config|
          begin
            r=Redis.new(config)
            r.ping
            #expect the exception.
            out "THIS SERVER IS BACK! LIKE THE MCRIB"
            @dead_socket.puts Marshal.dump(config)
            Process.kill(:USR1,Process.ppid) #let the parent know to respawn.
            true
          rescue
            out 'still down'
            false
          ensure
            Redis.current.quit
          end
        end
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
