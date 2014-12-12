require 'weakref'

module Lita
  module Handlers
    class Enhance < Handler
      class Enhancer
        @@subclasses = []

        @@start = "*"
        @@end = "*"

        def self.all
          @@subclasses.select! {|x| x.weakref_alive? }
          @@subclasses
        end

        def self.inherited(subclass)
          @@subclasses << WeakRef.new(subclass)
        end

        def render(node, original, level)
          node ? "#{@@start}#{node.render(level)}#{@@end}" : original
        end

        def max_level
          4
        end
      end

      require 'lita/handlers/enhance/enhancers/hostname_enhancer'
      require 'lita/handlers/enhance/enhancers/instance_id_enhancer'
      require 'lita/handlers/enhance/enhancers/ip_enhancer'
      require 'lita/handlers/enhance/enhancers/mac_address_enhancer'
    end
  end
end

