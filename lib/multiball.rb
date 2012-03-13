require 'hash_driver' #need some autoload magic or something?
require 'ball'
require 'yaml'
require 'socket'
require 'redis'

module Multiball

  class << self #the arrays may be extraneous now.
    attr_accessor :servers, :preferred_servers, :affinity, :driver, :server_queue, :preferred_queue
  end
  
  def self.set_config!(server_hash)
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

  def self.get_server(config)
  	return nil if Multiball.driver.nil?
  	Multiball.driver.send(:new, config)
  end

end