require 'chef'
require 'thread'
require 'weakref'

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
        @@last_refreshed = nil
        @@enhancers = Enhancer.all.map(&:new)

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
        key = last_message_key(response)
        level_key = key + ":level"

        level = response.matches[0][1]
        blurry_string = response.matches[0][3]
        return if blurry_string == "stats"

        if blurry_string && !blurry_string.empty?
          redis.setex(key, config.blurry_message_ttl, blurry_string)

          if level
            level = level.to_i
          else
            level = 1
          end

          redis.setex(level_key, config.blurry_message_ttl, level.to_i)
        else
          blurry_string = redis.get(key)
        end

        unless blurry_string
          response.reply("(failed) I need a string to enhance")
          return
        end

        if level
          level = level.to_i
          redis.setex(level_key, config.blurry_message_ttl, level)
        else
          log.debug { "Getting level from redis" }
          level = redis.incr(level_key)
        end

        redis.expire(key, config.blurry_message_ttl)
        redis.expire(level_key, config.blurry_message_ttl)

        if level > max_level
          response.reply("Cannot enhance above level #{max_level}")
          return
        elsif level < 1
          response.reply("Level must be between 1 and #{max_level}")
          return
        end

        log.debug { "Enhancing (level: #{level}):\n#{blurry_string}" }

        INDEX_MUTEX.synchronize do
          @@enhancers.each do |e|
            e.enhance!(blurry_string, level)
          end
        end

        if config.add_quote
          response.reply('/quote ' + blurry_string)
        else
          response.reply(blurry_string)
        end
      end

      def stats(response)
        INDEX_MUTEX.synchronize do
          response_msg = "Last refreshed: #{@@last_refreshed || 'never'}"
          response_msg += ("\nRefreshes every %.2f minutes" % (config.refresh_interval / 60.0))
          @@enhancers.each do |e|
            response_msg += "\n#{e}"
          end
          response.reply(response_msg)
        end
      end

      private
        class Node
          attr_accessor :name, :dc, :environment, :fqdn

          def self.from_chef_node(node)
            new.tap do |n|
              n.name = node.name
              n.dc = if node['ec2']
                       node['ec2']['placement_availability_zone']
                     elsif node['cloud']
                       node['cloud']['provider']
                     end
              n.environment = node.environment
              n.fqdn = node['fqdn']
            end
          end

          def render(level)
            case level
            when 1 then name
            when 2 then "#{name} (#{dc})"
            when 3 then "#{name} (#{dc}, #{environment})"
            when 4 then "#{fqdn} (#{dc}, #{environment})"
            end
          end
        end

        class Enhancer
          @@subclasses = []

          @@start = "*"
          @@end = "*"

          def self.all
            @@subclasses.select! {|x| x.weakref_alive? }
            @@subclasses
          end

          def self.inherited(subclass)
            @@subclasses << WeakRef.new(subclass)
          end

          def render(node, original, level)
            node ? "#{@@start}#{node.render(level)}#{@@end}" : original
          end

          def max_level
            4
          end
        end

        require 'lita/handlers/enhancers/hostname_enhancer'
        require 'lita/handlers/enhancers/instance_id_enhancer'
        require 'lita/handlers/enhancers/ip_enhancer'
        require 'lita/handlers/enhancers/mac_address_enhancer'

        # This mutex must be obtained to refresh the index
        REFRESH_MUTEX = Mutex.new unless defined?(REFRESH_MUTEX)

        # This mutex must be obtains to update the index with new data, or to use the index to enhance some text
        INDEX_MUTEX   = Mutex.new unless defined?(INDEX_MUTEX)

        def lock_and_refresh_index
          REFRESH_MUTEX.synchronize do
            refresh_index
          end
        end

        def refresh_index
          log.info { "Refreshing enhance index..." }

          enhancers = Enhancer.all.map(&:new)

          config.knife_configs.each do |_, config_path|
            index(config_path, enhancers)
          end

          INDEX_MUTEX.synchronize do
            @@last_refreshed = Time.now
            @@enhancers = enhancers

            log.info { "Refreshed enhance index" }

            @@enhancers.each do |e|
              log.debug { e.to_s }
            end
          end

          # Refreshing the index pulls a lot of large objects into memory,
          # forcing a GC run to ensure that our heap doesn't grow aggressively.
          GC.start

          nil
        end

        def index(chef_config_path, enhancers)
          log.info { "Indexing #{chef_config_path}" }

          Chef::Config.from_file(File.expand_path(chef_config_path))
          query = Chef::Search::Query.new

          query.search("node", "*:*") do |chef_node|
            node = Node.from_chef_node(chef_node)
            enhancers.each {|e| e.index(chef_node, node) }
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
