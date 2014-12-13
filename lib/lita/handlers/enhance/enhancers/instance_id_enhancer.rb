module Lita
  module Handlers
    class Enhance
      class InstanceIdEnhancer < Enhancer
        INSTANCE_ID_REGEX = /i-[0-9a-f]{8}/

        def initialize(redis)
          super
          @nodes_by_instance_id = {}
        end

        def index(chef_node, node)
          if chef_node['ec2']
            @nodes_by_instance_id[chef_node['ec2']['instance_id']] = node.name
          end
        end

        def enhance!(string, level)
          string.gsub!(INSTANCE_ID_REGEX) do |instance_id|
            node = self.node(@nodes_by_instance_id[instance_id])
            render(node, instance_id, level)
          end
        end

        def to_s
          "#{self.class.name}: #{@nodes_by_instance_id.size} instance IDs indexed"
        end
      end
    end
  end
end
