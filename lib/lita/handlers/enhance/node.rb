module Lita
  module Handlers
    class Enhance < Handler
      class Node
        attr_accessor :name, :dc, :environment, :fqdn

        def self.from_chef_node(node)
          new.tap do |n|
            n.name = node.name
            n.dc = if node['ec2']
                     node['ec2']['placement_availability_zone']
                   elsif node['cloud']
                     node['cloud']['provider']
                   end
            n.environment = node.environment
            n.fqdn = node['fqdn']
          end
        end

        # Creates a new Node instance and loads its data from Redis
        def self.load(redis, name)
          node = nil

          node_data_json = redis.hget('nodes', name)
          if node_data_json
            node_data = JSON.parse(node_data_json)
            node = self.new

            node_data.each do |key, value|
              node.send("#{key}=", value)
            end
          end

          node
        end

        # Stores this node in Redis for later retrieval
        def store!(redis)
          node_data_json = JSON.generate(self.as_json)
          redis.hset('nodes', self.name, node_data_json)
        end

        def as_json
          {name: name, dc: dc, environment: environment, fqdn: fqdn}
        end

        def render(level)
          case level
          when 1 then name
          when 2 then "#{name} (#{dc})"
          when 3 then "#{name} (#{dc}, #{environment})"
          when 4 then "#{fqdn} (#{dc}, #{environment})"
          end
        end
      end
    end
  end
end
