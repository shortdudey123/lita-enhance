require 'lita/handlers/enhance/node_index'

module Lita
  module Handlers
    class Enhance
      class IpEnhancer < Enhancer
        IP_REGEX = /([0-9]{1,3}\.){3}[0-9]{1,3}/

        def initialize(redis)
          super
          @nodes_by_ip = NodeIndex.new(redis, 'nodes_by_ip')
        end

        def index(chef_node, node)
          @nodes_by_ip[chef_node['ipaddress']] = node

          if chef_node['cloud']
            @nodes_by_ip[chef_node['cloud']['local_ipv4']] = node
            @nodes_by_ip[chef_node['cloud']['public_ipv4']] = node
          end

          if chef_node['cloud_v2']
            if chef_node['cloud_v2']['public_ipv4_addrs']
              ips = chef_node['cloud_v2']['public_ipv4_addrs']
              ips.each {|ip| @nodes_by_ip[ip] = node }
            end
            if chef_node['cloud_v2']['local_ipv4_addrs']
              ips = chef_node['cloud_v2']['local_ipv4_addrs']
              ips.each {|ip| @nodes_by_ip[ip] = node }
            end
          end
        end

        def enhance!(string, level)
          string.gsub!(IP_REGEX) do |ip|
            node = @nodes_by_ip[ip]
            render(node, ip, level)
          end
        end

        def to_s
          "#{self.class.name}: #{@nodes_by_ip.size} IPs indexed"
        end
      end
    end
  end
end
