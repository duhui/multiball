module Multiball
  class Ball #use Forwardable maybe? But method_missing is easiest although there's apparently a performance hit?

  	def method_missing(method_sym, *arguments, &block)
  		Multiball.get.send(method_sym, *arguments, &block)
  	end

  end
end
