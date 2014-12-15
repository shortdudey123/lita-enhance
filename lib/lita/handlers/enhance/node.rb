module Lita
  module Handlers
    class Enhance < Handler
      class Node
        attr_accessor :name, :dc, :environment, :fqdn, :last_seen_at

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
            n.last_seen_at = Time.now
          end
        end

        # Creates a new Node instance and loads its data from Redis
        def self.load(redis, name)
          node = nil

          node_data_json = redis.hget('nodes', name)
          if node_data_json
            node_data = JSON.parse(node_data_json)
            node = self.from_json(node_data)
          end

          node
        end

        # Stores this node in Redis for later retrieval
        def store!(redis)
          node_data_json = JSON.generate(self.as_json)
          redis.hset('nodes', self.name, node_data_json)
        end

        def self.from_json(json)
          self.new.tap do |node|
            %w(name dc environment fqdn).each do |field|
              node.send("#{field}=", json[field])
            end
            node.last_seen_at = Time.parse(json['last_seen_at']) if json['last_seen_at']
          end
        end

        def as_json
          {name: name, dc: dc, environment: environment, fqdn: fqdn, last_seen_at: last_seen_at}
        end

        def render(level)
          case level
          when 1 then name
          when 2 then "#{name} (#{dc})"
          when 3 then "#{name} (#{dc}, #{environment})"
          when 4 then "#{name} (#{dc}, #{environment}, last seen #{last_seen_at})"
          when 5 then "#{fqdn} (#{dc}, #{environment}, last seen #{last_seen_at})"
          end
        end

        # True if this node appears to be gone away because we haven't seen it
        # for a while.
        def old?
          last_seen_at < (Time.now - 6 * 60 * 60)
        end
      end
    end
  end
end
