require 'lita/handlers/enhance/node_index'

module Lita
  module Handlers
    class Enhance
      class InstanceIdEnhancer < Enhancer
        INSTANCE_ID_REGEX = /i-[0-9a-f]{8}/

        def initialize(redis)
          super
          @nodes_by_instance_id = NodeIndex.new(redis, 'nodes_by_instance_id')
        end

        def index(chef_node, node)
          if chef_node['ec2']
            @nodes_by_instance_id[chef_node['ec2']['instance_id']] = node
          end
        end

        def enhance!(string, level)
          substitutions = []
          string.scan(INSTANCE_ID_REGEX) do |instance_id|
            range = Range.new(*Regexp.last_match.offset(0))

            node = @nodes_by_instance_id[instance_id]
            if node
              new_text = render(node, level)
              substitutions << Substitution.new(range, new_text)
            end
          end
          substitutions
        end

        def to_s
          "#{self.class.name}: #{@nodes_by_instance_id.size} instance IDs indexed"
        end
      end
    end
  end
end
