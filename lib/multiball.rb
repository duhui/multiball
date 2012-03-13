require 'yaml'
require 'socket'
require 'redis'

class Multiball

  class << self
    attr_accessor :servers, :preferred_servers, :affinity
  end

  def self.set_config!(server_hash)
      Multiball.servers=Hash[server_hash.collect{|name,config|[name, get_server(config)]}]
      Multiball.preferred_servers=server_hash.select{|name,config| Multiball.prefer?(name,config)}.keys
      Multiball.affinity=Multiball.preferred_servers.any?
  end

  def self.prefer?(name,config) #TODO: allow specify in config
    begin
      value=Addrinfo.getaddrinfo(name.to_s,0).select{|addr| addr.ip_address=="127.0.0.1"}.any?
    rescue SocketError
      false
    end
  end

  #You could really turn this into some generic mechanism and make redis just a 'driver'
  def self.get_server(config)
    Redis.new config
  end
end
