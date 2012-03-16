require 'lawger'
module Multiball
	module Multicaster

		attr_accessor :proxy

		def multi_method(proxied_thing, *args)
			self.proxy=proxied_thing
			args.each do |method_to_define|
				define_method method_to_define do |*method_args, &block|
					Multiball.servers.each do |key,value| 
						begin
							value.send(proxied_thing).send method_to_define, *method_args, &block
						rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
							Multiball.send_to_purgatory value
						end
					end
				end
			end
		end

	end
end