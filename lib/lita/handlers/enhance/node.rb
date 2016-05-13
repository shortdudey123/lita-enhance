module Lita
  module Handlers
    class Enhance < Handler
      class Node
        attr_accessor :name, :size, :dc, :environment, :fqdn, :last_seen_at

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
            %w(name size dc environment fqdn).each do |field|
              node.send("#{field}=", json[field])
            end
            node.last_seen_at = Time.parse(json['last_seen_at']) if json['last_seen_at']
          end
        end

        def as_json
          {name: name, dc: dc, size: size, environment: environment, fqdn: fqdn, last_seen_at: last_seen_at}
        end

        def render(level)
          case level
          when 1 then name
          when 2 then "#{name} (#{dc}, #{size})"
          when 3 then "#{name} (#{dc}, #{size}, #{environment})"
          when 4 then "#{name} (#{dc}, #{size}, #{environment}, last seen #{last_seen_at})"
          when 5 then "#{fqdn} (#{dc}, #{size}, #{environment}, last seen #{last_seen_at})"
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
