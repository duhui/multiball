require 'yaml'
require 'redis'

class Multiball

	class << self
		attr_accessor :servers
	end

	def self.set_config(server_hash)
		Multiball.servers=server_hash.collect{|config|get_server(config)}
	end

	private
		def self.get_server(config)
			Redis.new config
		end
end