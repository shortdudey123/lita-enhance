module Lita
  module Handlers
    class Enhance
      class HostnameEnhancer < Enhancer
        HOSTNAME_REGEX = /\b((([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)+([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]))\b/

        def initialize(redis)
          super
          @nodes_by_hostname = {}
          @nodes_by_short_hostnames = {}
        end

        def index(chef_node, node)
          map_hostname_to_node(chef_node['fqdn'], node)

          if chef_node['cloud']
            map_hostname_to_node(chef_node['cloud']['local_hostname'], node)
            map_hostname_to_node(chef_node['cloud']['public_hostname'], node)
          end

          if chef_node['cloud_v2']
            map_hostname_to_node(chef_node['cloud_v2']['local_hostname'], node)
            map_hostname_to_node(chef_node['cloud_v2']['public_hostname'], node)
          end
        end

        def enhance!(string, level)
          string.gsub!(HOSTNAME_REGEX) do |hostname|
            node = self.node(@nodes_by_hostname[hostname])
            render(node, hostname, level)
          end
          string.gsub!(short_hostname_regex) do |hostname|
            node = self.node(@nodes_by_short_hostnames[hostname])
            render(node, hostname, level)
          end
        end

        def short_hostname_regex
          @short_hostname_regex ||= /\b(?<!\*)#{Regexp.union(@nodes_by_short_hostnames.keys)}\b(?<!\*)/
        end

        def to_s
          "#{self.class.name}: #{@short_hostnames.size} short hostnames, #{@nodes_by_hostname.size} long hostnames indexed"
        end

        private

        def map_hostname_to_node(hostname, node)
          return if hostname.nil?

          short_hostname = hostname.split('.')[0]

          @nodes_by_hostname[hostname] = node.name
          @nodes_by_short_hostnames[short_hostname] = node.name
        end
      end
    end
  end
end
