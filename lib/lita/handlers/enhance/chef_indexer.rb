require 'chef'

module Lita
  module Handlers
    class Enhance < Handler
      # This class is responsible for indexing Chef servers to extract
      # enhanceable data to populate the enhance indices.
      class ChefIndexer
        attr_reader :last_refreshed

        attr_reader :redis, :knife_configs

        def initialize(redis, knife_configs)
          @redis = redis
          @knife_configs = knife_configs
        end

        def refresh
          log.info { "Refreshing enhance index..." }

          @enhancers = Enhancer.all.map do |enhancer_klass|
            enhancer_klass.new(redis)
          end

          self.knife_configs.each do |_, config_path|
            index(config_path, @enhancers)
          end

          @last_refreshed = Time.now

          log.info { "Refreshed enhance index" }

          @enhancers.each do |e|
            log.debug { e.to_s }
          end

          # Refreshing the index pulls a lot of large objects into memory,
          # forcing a GC run to ensure that our heap doesn't grow aggressively.
          GC.start

          nil
        end

        private

        def index(chef_config_path, enhancers)
          log.info { "Indexing #{chef_config_path}" }

          Chef::Config.from_file(File.expand_path(chef_config_path))
          query = Chef::Search::Query.new

          query.search("node", "*:*") do |chef_node|
            node = Node.from_chef_node(chef_node)
            node.store!(redis)

            enhancers.each {|e| e.index(chef_node, node) }
          end
        end

        def log
          Lita.logger
        end
      end
    end
  end
end
