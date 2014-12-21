module Lita
  module Handlers
    class Enhance < Handler
      # Represents a session of message enhancing. This class is the entry
      # point into logic for enhancing a string. Since state is stored in
      # Redis, a new session can be created for each interaction.
      class Session
        # A redis namespace under which we will store our data
        attr_reader :redis

        # The key by which the previous enhanced messages should be remembered.
        attr_reader :last_message_key

        # How long to remember previous messages (in seconds)
        attr_reader :last_message_ttl

        def initialize(redis, last_message_key, last_message_ttl)
          @redis = redis
          @last_message_key = last_message_key
          @last_message_ttl = last_message_ttl
        end

        # Returns the last level of enhancement that was performed in this
        # session. Using this value it is possible to implicitly raise the
        # level.
        def last_level
          last_level_raw = redis.get(last_level_key)
          last_level_raw && last_level_raw.to_i
        end

        # Returns the last user supplied message that was enhanced for this
        # session. Using this value, it is possible to re-enhance this string.
        def last_message
          redis.get(last_message_key)
        end

        # Enhances message at the supplied level.
        def enhance!(message, level)
          log.debug { "Enhancing (level: #{level}):\n#{message}" }

          redis.setex(last_message_key, last_message_ttl, message)
          redis.setex(last_level_key, last_message_ttl, level)

          @enhancers = Enhancer.all.map do |enhancer_klass|
            enhancer_klass.new(redis)
          end

          @enhancers.each do |e|
            e.enhance!(message, level)
          end
        end

        private
        def log
          Lita.logger
        end

        def last_level_key
          last_message_key + ":level"
        end
      end
    end
  end
end
