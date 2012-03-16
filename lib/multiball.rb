require 'hash_driver' #need some autoload magic or something?
require 'ball'
require 'yaml'
require 'socket'
require 'redis'

module Multiball
  @@purgatory_lock = Mutex.new

  class << self #the arrays may be extraneous now.
    attr_accessor :servers, :preferred_servers, :affinity, :driver, :server_queue, :preferred_queue, :purgatory
  end

  def self.set_config!(server_hash)
    Multiball.purgatory=[]
    Multiball.servers=Hash[server_hash.collect{|name,config|[name, get_server(config)]}]
    Multiball.server_queue = Queue.new
    Multiball.preferred_queue = Queue.new
    Multiball.servers.values.each{|server| Multiball.server_queue << server}
    Multiball.preferred_servers=server_hash.select{|name,config| Multiball.prefer?(name,config)}.keys
    Multiball.preferred_servers.each{|value| Multiball.preferred_queue << Multiball.servers[value] }
    Multiball.affinity=Multiball.preferred_servers.any?
  end

  def self.prefer?(name,config) #TODO: allow specify in config
    begin
      value=Addrinfo.getaddrinfo(name.to_s,0).select{|addr| addr.ip_address=="127.0.0.1"}.any?
    rescue SocketError
      false
    end
  end

  #Using Queue here as a faux ring buffer.
  #TODO: Handle no resources, plus reintroduction mechanism
  def self.get
    if Multiball.affinity
      ball = Multiball.preferred_queue.pop
      Multiball.preferred_queue << ball
      return ball
    else
      ball = Multiball.server_queue.pop
      Multiball.server_queue << ball
      return ball
    end
  end

  def self.send_to_purgatory(server)
    @@purgatory_lock.synchronize do
      break if(Multiball.purgatory.include? server) #late to the party
      if (Multiball.servers.size - Multiball.purgatory.size) > 0
        ball=nil
        until ball == server
          ball = Multiball.server_queue.pop
          Multiball.server_queue << ball unless server == ball
        end
      end
      if (Multiball.preferred_servers.size - Multiball.purgatory.select{|purged| Multiball.preferred_servers.include? purged}.size) > 0
        ball=nil
        until ball == server
          ball = Multiball.preferred_queue.pop
          Multiball.preferred_queue << ball unless server == ball
        end
      end
      Multiball.purgatory << server
    end
  end

  def self.get_server(config)
    return nil if Multiball.driver.nil?
    Multiball.driver.send(:new, config)
  end

end
