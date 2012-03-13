require 'multicaster'
module Multiball
	class HashDriver
		extend Multicaster

		attr_accessor :hash

		multi_method :hash, :merge!, :[]

		def hashie
			hash
		end

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