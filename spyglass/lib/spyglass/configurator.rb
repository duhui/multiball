module Spyglass
  class Configurator
    # A hash of key => default
    OPTIONS = {
      :port => 4222,
      :host => '0.0.0.0',
      :workers => 5,
      :timeout => 300,
      :config_ru_path => 'config.ru',
      :verbose => false,
      :vverbose => false,
      :multicast_address => "225.99.99.99", 
      :multicast_port => 6370,
      :redis_hosts => [{:host => "localhost", :port => 6379}, 
                       {:host => "localhost", :port => 6667}]
    }
    
    class << self
      OPTIONS.each do |key, default|
        # attr_writer key
      
        define_method(key) do |*args|
          arg = args.shift
          if arg
            instance_variable_set("@#{key}", arg)
          else
            instance_variable_get("@#{key}") || default
          end
        end
      end
    end
  end
  
  Config = Configurator
end
