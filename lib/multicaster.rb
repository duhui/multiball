module Multiball
	module Multicaster

		def multi_method(proxied_thing, *args)
			args.each do |method_to_define|
				define_method method_to_define do |*method_args|
					Multiball.servers.each{|key,value|
					 value.send(proxied_thing).send method_to_define, *method_args}
				end
			end
		end

	end
end