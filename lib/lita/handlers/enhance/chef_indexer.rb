require 'chef'
require 'chef/knife/core/generic_presenter'

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
          log.debug { "Refreshing enhance index..." }

          self.knife_configs.each do |_, config_path|
            index(config_path, @enhancers)
          end

          @last_refreshed = Time.now

          log.debug { "Refreshed enhance index" }

          # Refreshing the index pulls a lot of large objects into memory,
          # forcing a GC run to ensure that our heap doesn't grow aggressively.
          GC.start

          nil
        end

        def index_chef_node(chef_node)
          node = node_from_chef_node(chef_node)
          node.store!(redis)

          index_hostname(chef_node, node)
          index_instanceid(chef_node, node)
          index_ip(chef_node, node)
          index_mac_address(chef_node, node)
        end

        def node_from_chef_node(chef_node)
          Node.new.tap do |n|
            n.name = chef_node.name
            n.size = chef_fetch_attribute(chef_node, Lita.config.handlers.enhance.size_attribute)
            n.dc = if chef_node['ec2']
                     chef_node['ec2']['placement_availability_zone']
                   elsif chef_node['cloud']
                     chef_node['cloud']['provider']
                   end
            n.environment = chef_node.environment
            n.fqdn = chef_node['fqdn']
            n.last_seen_at = Time.now
          end
        end

        private

        def index(chef_config_path, enhancers)
          log.debug { "Indexing #{chef_config_path}" }

          Chef::Config.from_file(File.expand_path(chef_config_path))
          query = Chef::Search::Query.new

          query.search("node", "*:*") do |chef_node|
            index_chef_node(chef_node)
          end
        end

        def index_hostname(chef_node, node)
          enhancer = HostnameEnhancer.new(redis)

          enhancer.index(chef_node['fqdn'], node)

          if chef_node['cloud']
            enhancer.index(chef_node['cloud']['local_hostname'], node)
            enhancer.index(chef_node['cloud']['public_hostname'], node)
          end

          if chef_node['cloud_v2']
            enhancer.index(chef_node['cloud_v2']['local_hostname'], node)
            enhancer.index(chef_node['cloud_v2']['public_hostname'], node)
          end
        end

        def index_instanceid(chef_node, node)
          enhancer = InstanceIdEnhancer.new(redis)

          if chef_node['ec2']
            enhancer.index(chef_node['ec2']['instance_id'], node)
          end
        end

        def index_ip(chef_node, node)
          enhancer = IpEnhancer.new(redis)

          enhancer.index(chef_node['ipaddress'], node)

          if chef_node['cloud']
            enhancer.index(chef_node['cloud']['local_ipv4'], node)
            enhancer.index(chef_node['cloud']['public_ipv4'], node)
          end

          if chef_node['cloud_v2']
            if chef_node['cloud_v2']['public_ipv4_addrs']
              ips = chef_node['cloud_v2']['public_ipv4_addrs']
              ips.each {|ip| enhancer.index(ip, node) }
            end
            if chef_node['cloud_v2']['local_ipv4_addrs']
              ips = chef_node['cloud_v2']['local_ipv4_addrs']
              ips.each {|ip| enhancer.index(ip, node) }
            end
          end
        end

        def index_mac_address(chef_node, node)
          enhancer = MacAddressEnhancer.new(redis)

          if chef_node['macaddress']
            enhancer.index(chef_node['macaddress'], node)
          end
        end

        def log
          Lita.logger
        end

        def chef_presenter
          @generic_presenter ||= Chef::Knife::Core::GenericPresenter.new(Chef::Log, Chef::Config)
        end

        def chef_fetch_attribute(chef_node, attr)
          chef_presenter.extract_nested_value(chef_node, attr)
        end
      end
    end
  end
end
