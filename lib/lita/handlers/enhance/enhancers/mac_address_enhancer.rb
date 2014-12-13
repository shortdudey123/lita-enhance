module Lita
  module Handlers
    class Enhance
      class MacAddressEnhancer < Enhancer
        # TODO: enhance unknown MAC address with OUI names http://standards.ieee.org/develop/regauth/oui/oui.txt

        MAC_ADDRESS_REGEX = /([0-9a-f]{2}:){5}[0-9a-f]{2}/i

        def initialize(redis)
          super
          @nodes_by_mac_address = {}
        end

        def index(chef_node, node)
          if chef_node['macaddress']
            @nodes_by_mac_address[chef_node['macaddress'].downcase] = node.name
          end
        end

        def enhance!(string, level)
          string.gsub!(MAC_ADDRESS_REGEX) do |mac_address|
            node = self.node(@nodes_by_mac_address[mac_address.downcase])
            render(node, mac_address, level)
          end
        end

        def to_s
          "#{self.class.name}: #{@nodes_by_mac_address.size} MAC addresses indexed"
        end
      end
    end
  end
end
