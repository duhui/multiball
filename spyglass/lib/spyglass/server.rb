module Spyglass

  class Server
    include Singleton
    include Logging

    def start
      # Opens the main listening socket for the server. Now the server is responsive to
      # incoming connections.
      sock = UNIXServer.new(Config.host)
      out "Listening on UNIXSocket!"
      Lookout.instance.start(sock)
    end

    def stop
      File.delete(Config.host)
    end
  end
end

