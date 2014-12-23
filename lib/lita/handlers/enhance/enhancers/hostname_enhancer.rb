require 'lita/handlers/enhance/node_index'
require 'lita/handlers/enhance/enhancer'

module Lita
  module Handlers
    class Enhance
      class HostnameEnhancer < Enhancer
        HOSTNAME_REGEX = /\b(?:(?:(?:[a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)+(?:[A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]))\b/

        def initialize(redis)
          super
          @nodes_by_hostname = NodeIndex.new(redis, 'nodes_by_hostname')
          @nodes_by_short_hostname = NodeIndex.new(redis, 'nodes_by_short_hostname')
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
          substitutions = []
          string.scan(HOSTNAME_REGEX) do
            match = Regexp.last_match
            hostname = match.to_s
            range = (match.begin(0)...match.end(0))

            node = @nodes_by_hostname[hostname]
            if node
              new_text = render(node, level)
              substitutions << Substitution.new(range, new_text)
            end
          end
          string.scan(short_hostname_regex) do
            match = Regexp.last_match
            hostname = match.to_s
            range = (match.begin(0)...match.end(0))

            node = @nodes_by_short_hostname[hostname]
            if node
              new_text = render(node, level)
              sub = Substitution.new(range, new_text)
              unless substitutions.any? {|s| s.overlap?(sub) }
                substitutions << Substitution.new(range, new_text)
              end
            end
          end

          substitutions
        end

        def short_hostname_regex
          @short_hostname_regex ||= /\b(?<!\*)#{Regexp.union(@nodes_by_short_hostname.keys)}\b(?<!\*)/
        end

        def to_s
          "#{self.class.name}: #{@nodes_by_short_hostname.size} short hostnames, #{@nodes_by_hostname.size} long hostnames indexed"
        end

        private

        def map_hostname_to_node(hostname, node)
          return if hostname.nil?

          short_hostname = hostname.split('.')[0]

          @nodes_by_hostname[hostname] = node
          @nodes_by_short_hostname[short_hostname] = node
        end
      end
    end
  end
end
