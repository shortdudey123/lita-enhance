require 'thread'

require 'lita/handlers/enhance/chef_indexer'
require 'lita/handlers/enhance/node'
require 'lita/handlers/enhance/enhancer'
require 'lita/handlers/enhance/session'

module Lita
  module Handlers
    class Enhance < Handler
      on :loaded, :setup_background_refresh

      route(
        /^refresh enhance$/,
        :refresh,
        command: true
      )

      route(
        /^enhance stats$/,
        :stats,
        command: true
      )

      route(
        /\Aenhance(\slvl:([0-9]))?(\s(.*))?\z/m,
        :enhance,
        command: true,
        help: {
          'enhance <anything>' => 'Enhances details in your text. https://www.youtube.com/watch?v=Vxq9yj2pVWk'
        }
      )

      def self.default_config(config)
        config.knife_configs = {}
        if File.exist?('~/.chef/knife.rb')
          config.knife_configs['default'] = '~/.chef/knife.rb'
        end

        config.refresh_interval = 15 * 60
        config.add_quote = true

        # How long to remember the previously enhanced message for.
        config.blurry_message_ttl = 7 * 24 * 60 * 60 # seconds
      end

      def setup_background_refresh(payload)
        @@chef_indexer = ChefIndexer.new(redis, config.knife_configs)
        @@enhancers = Enhancer.all.map do |enhancer_klass|
          enhancer_klass.new(redis)
        end

        bg_refresh = proc do
          begin
            lock_and_refresh_index
          rescue => e
            # Keep error from killing background thread
            log.error { "#{e.message}\n#{e.backtrace.join("\n")}" }
          end
        end

        log.info { "Will refresh enhance index every #{config.refresh_interval} seconds" }
        after(0, &bg_refresh)
        every(config.refresh_interval, &bg_refresh)
      end

      def refresh(response)
        response.reply("Will refresh enhance index...")

        after(0) do
          begin
            lock_and_refresh_index
            response.reply("(successful) Refreshed enhance index")
          rescue => e
            response.reply("(failed) Failed to refresh enhance index. Check the logs.")
            log.info { "#{e.message}\n#{e.backtrace.join("\n")}" }
          end
        end
      end

      def enhance(response)
        level = response.matches[0][1]
        level = level.to_i if level

        blurry_string = response.matches[0][3]
        return if blurry_string == "stats"

        key = last_message_key(response)
        level_key = key + ":level"

        session = Session.new(redis, key, config.blurry_message_ttl)

        if blurry_string && !blurry_string.empty?
          level = 1 unless level
        else
          blurry_string = session.last_message
        end

        unless blurry_string
          response.reply("(failed) I need a string to enhance")
          return
        end

        level = session.last_level + 1 unless level

        if level > max_level
          response.reply("Cannot enhance above level #{max_level}")
          return
        elsif level < 1
          response.reply("Level must be between 1 and #{max_level}")
          return
        end

        enhanced_message = session.enhance!(blurry_string, level)

        if enhanced_message != blurry_string
          if config.add_quote
            response.reply('/quote ' + enhanced_message)
          else
            response.reply(enhanced_message)
          end
        else
          response.reply('(nothingtodohere) I could not find anything to enhance')
        end
      end

      def stats(response)
        INDEX_MUTEX.synchronize do
          response_msg = "Last refreshed: #{@@chef_indexer.last_refreshed || 'never'}"
          response_msg += ("\nRefreshes every %.2f minutes" % (config.refresh_interval / 60.0))
          @@enhancers.each do |e|
            response_msg += "\n#{e}"
          end
          response.reply(response_msg)
        end
      end

      private
        # This mutex must be obtained to refresh the index
        REFRESH_MUTEX = Mutex.new unless defined?(REFRESH_MUTEX)

        # This mutex must be obtains to update the index with new data, or to use the index to enhance some text
        INDEX_MUTEX   = Mutex.new unless defined?(INDEX_MUTEX)

        def lock_and_refresh_index
          REFRESH_MUTEX.synchronize do
            @@chef_indexer.refresh
          end
        end

        def last_message_key(response)
          response.message.source.room || response.message.source.user.id
        end

        def max_level
          @@enhancers.map {|x| x.max_level }.max
        end
    end


    Lita.register_handler(Enhance)
  end
end
