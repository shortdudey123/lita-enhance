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
        response.reply(t 'refresh.queued')

        after(0) do
          begin
            lock_and_refresh_index
            response.reply(t 'refresh.success')
          rescue => e
            response.reply(t 'refresh.failed')
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
          response.reply(t 'enhance.message_required')
          return
        end

        level = session.last_level + 1 unless level

        if level > max_level
          response.reply(t 'enhance.level_too_high', max_level: max_level)
          return
        elsif level < 1
          response.reply(t 'enhance.level_too_low', max_level: max_level)
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
          response.reply(t 'enhance.nothing_to_enhance')
        end
      end

      def stats(response)
        INDEX_MUTEX.synchronize do
          response_msg = t('stats.last_refreshed', last_refreshed: (@@chef_indexer.last_refreshed.to_s || 'never'))
          response_msg += "\n" + t('stats.refresh_frequency', refresh_mins: ('%.2f' % (config.refresh_interval / 60.0)))
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
