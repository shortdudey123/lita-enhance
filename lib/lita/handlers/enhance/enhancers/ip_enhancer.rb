require 'lita/handlers/enhance/node_index'

module Lita
  module Handlers
    class Enhance
      class IpEnhancer < Enhancer
        IP_REGEX = /(?:[0-9]{1,3}\.){3}[0-9]{1,3}/

        def initialize(redis)
          super
          @nodes_by_ip = NodeIndex.new(redis, 'nodes_by_ip')
        end

        def index(ip, node)
          @nodes_by_ip[ip] = node
        end

        def enhance!(string, level)
          substitutions = []
          string.scan(IP_REGEX) do 
            match = Regexp.last_match
            ip = match.to_s
            range = (match.begin(0)...match.end(0))

            node = @nodes_by_ip[ip]
            if node
              new_text = render(node, level)
              substitutions << Substitution.new(range, new_text)
            end
          end
          substitutions
        end

        def to_s
          "#{self.class.name}: #{@nodes_by_ip.size} IPs indexed"
        end
      end
    end
  end
end
