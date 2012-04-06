require "test/unit"
require 'redis'

class SocketTest < Test::Unit::TestCase
	def test_stress
		redis = Redis.new(:port => 4222)
		10000.times do |i|
  			set = redis.set("foobar#{i}", "foobar#{i}!!!")
  			assert_equal "OK", set
  			unless i < 1
  				result= redis.get("foobar#{i-1}")
	  			assert_equal "foobar#{i-1}!!!", result
	  		end
  		end
	end
end
