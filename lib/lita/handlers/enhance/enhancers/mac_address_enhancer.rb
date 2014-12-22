require 'lita/handlers/enhance/node_index'

module Lita
  module Handlers
    class Enhance
      class MacAddressEnhancer < Enhancer
        # TODO: enhance unknown MAC address with OUI names http://standards.ieee.org/develop/regauth/oui/oui.txt

        MAC_ADDRESS_REGEX = /([0-9a-f]{2}:){5}[0-9a-f]{2}/i

        def initialize(redis)
          super
          @nodes_by_mac_address = NodeIndex.new(redis, 'nodes_by_mac_address')
        end

        def index(chef_node, node)
          if chef_node['macaddress']
            @nodes_by_mac_address[chef_node['macaddress'].downcase] = node
          end
        end

        def enhance!(string, level)
          substitutions = []
          string.scan(MAC_ADDRESS_REGEX) do
            match = Regexp.last_match
            mac_address = match.to_s
            range = (match.begin(0)...match.end(0))

            node = @nodes_by_mac_address[mac_address.downcase]
            if node
              new_text = render(node, level)
              substitutions << Substitution.new(range, new_text)
            end
          end
          substitutions
        end

        def to_s
          "#{self.class.name}: #{@nodes_by_mac_address.size} MAC addresses indexed"
        end
      end
    end
  end
end
