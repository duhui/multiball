module Multiball
	class RedisDriver
		extend Forwardable
		
		attr_accessor :redis

		def_delegators :@redis, :get
		
		def initialize(config)
			raise "No config!" if config.nil?
			self.redis= Redis.new(config[:config])
		end

	end
end