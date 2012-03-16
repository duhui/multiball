require 'multicaster'
module Multiball
  class BaseDriver
    extend Multicaster

    def method_missing(method_sym, *arguments, &block)
    	unless Multiball.purgatory.include? self
      		self.send(self.class.proxy).send(method_sym, *arguments, &block)
      	else
      		File.open('lawg', 'a'){|file| file.write "#{self.hash} IN! purgatory\n"}
      	end
    end

  end
end
