require 'multicaster'
require 'base_driver'
module Multiball
  class HashDriver < Multiball::BaseDriver

    attr_accessor :the_hash

    multi_method :the_hash, :merge!, :[]=, :reject!

    def hashie
      self.the_hash
    end

    def initialize(config)
      raise "No config!" if config.nil?
      self.the_hash= config[:config]
      if(config[:config][:go_bad])
        self.the_hash.instance_eval do 
          class << self
            define_method :reject! do
              raise Errno::ECONNREFUSED
            end
          end
        end
        self.delete(:go_bad) #What was I doing before??
      end
    end

    def set(key,value)
      self.the_hash[key]=value
    end

    def get(key)
      self.the_hash[key]
    end

  end
end
