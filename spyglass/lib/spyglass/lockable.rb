module Spyglass
  module Lockable
    def is_locked?
      !@redis.get('sync.lock').nil?
    end

    def release_lock
      @redis.del 'sync.lock'
    end

    def acquire_lock?
      if @redis.setnx 'sync.lock', Time.now.to_i+1001
        true
      else
        if Time.now.to_i < @redis.get('sync.lock').to_i #lock unexpired
          return false
        else
          lock = @redis.getset 'sync.lock', Time.now.to_i+1001
          return Time.now.to_i > lock.to_i
        end
      end
    end

  end
end
