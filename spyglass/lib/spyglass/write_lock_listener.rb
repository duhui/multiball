module Spyglass
  class WriteLockListener
    def initialize
      ip =  IPAddr.new(Config.multicast_address).hton + IPAddr.new("0.0.0.0").hton
      sock = UDPSocket.new
      sock.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, ip)
      sock.bind(Socket::INADDR_ANY, Config.multicast_port)
      loop do
        msg, info = sock.recvfrom(1024)
        puts "Received #{msg} from #{info[2]} (#{info[3]})/#{info[1]} len #{msg.size}"
        signal = (msg=="pause"? :USR1 : :USR2)
        Process.kill(signal,Process.ppid)
      end
    end
  end
end
