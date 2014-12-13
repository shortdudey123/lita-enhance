module Lita
  module Handlers
    class Enhance < Handler
      # Instances of this class represent indexes of nodes based on identifying
      # facets of that node.  Nodes are added to the index where the key is the
      # term that we're indexing on, and the value is the node that matches
      # that term.
      #
      # Nodes can then be later found in the index.
      class NodeIndex
        attr_reader :redis, :index_name

        def initialize(redis, index_name)
          @redis = redis
          @index_name = index_name
        end

        # Adds a node to the index
        def add(key, node)
          redis.hset(index_name, key, node.name)
        end

        # Finds a node in the index. A Node object is return if found, otherwise nil is returned.
        def search(key)
          node_name = redis.hget(index_name, key)
          Node.load(redis, node_name)
        end

        # Returns the number of keys that are stored in this index.
        def size
          redis.hlen(index_name)
        end
      end
    end
  end
end
