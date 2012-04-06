
require 'redis'
redis = Redis.new(:port => 4222)

10000.times do |i|
  begin
  	puts redis.set("foobar#{i}", "foobar#{i}!!!")
  	puts redis.get("foobar#{i-1}")
  rescue
  	p 'looks like a problem!'
  end
end
