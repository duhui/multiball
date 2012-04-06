module Spyglass

  class Server
    include Singleton
    include Logging

    def start
      # Opens the main listening socket for the server. Now the server is responsive to
      @sock = TCPServer.open(Config.host, Config.port)
      out "Listening on port #{Config.host}:#{Config.port}"
      Lookout.instance.start(@sock)
    end

    trap(:QUIT) do
        verbose "Received QUIT!"
        begin
          @sock.close
        rescue
          p 'could not close!'
        end
        exit
    end

    def stop
  #    File.delete(Config.host)
    end
  end
end

