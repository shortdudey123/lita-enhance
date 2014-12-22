require 'weakref'

module Lita
  module Handlers
    class Enhance < Handler
      class Enhancer
        @@subclasses = []

        @@current = %w(* *)
        @@old = %w(¿ ?)

        def self.all
          @@subclasses.select! {|x| x.weakref_alive? }
          @@subclasses
        end

        def self.inherited(subclass)
          @@subclasses << WeakRef.new(subclass)
        end

        attr_reader :redis

        def initialize(redis)
          @redis = redis
        end

        def render(node, level)
          "#{start_mark(node)}#{node.render(level)}#{end_mark(node)}"
        end

        def max_level
          5
        end

        private
        def start_mark(node)
          node.old? ? @@old.first : @@current.first
        end

        def end_mark(node)
          node.old? ? @@old.last : @@current.last
        end
      end

      class Substitution < Struct.new(:range, :new_text)
        def overlap?(other)
          range.cover?(other.range.begin) || other.range.cover?(range.end)
        end
      end

      require 'lita/handlers/enhance/enhancers/instance_id_enhancer'
      require 'lita/handlers/enhance/enhancers/ip_enhancer'
      require 'lita/handlers/enhance/enhancers/hostname_enhancer'
      require 'lita/handlers/enhance/enhancers/mac_address_enhancer'
    end
  end
end

