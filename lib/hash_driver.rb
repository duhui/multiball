module Multiball
	class HashDriver

		attr_accessor :hash

		def initialize(config)
			raise "No config!" if config.nil?
			self.hash= config[:config]
		end

		def set(key,value)
			self.hash[key]=value
		end

		def get(key)
			self.hash[key]
		end

	  	def method_missing(method_sym, *arguments, &block)
  			self.hash.send(method_sym, *arguments, &block)
  		end

	end
end