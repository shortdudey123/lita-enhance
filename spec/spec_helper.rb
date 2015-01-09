require "lita-enhance"
require "lita/rspec"

require 'pry'

RSpec.shared_context 'mocks' do
  include_context 'redis'

  def spec_data(file_name)
    File.read(File.expand_path("../data/#{file_name}", __FILE__))
  end

  let(:west2_chef_node) do
    chef_nodes.detect {|n| n.name == 'box01' }
  end

  let(:west1_chef_node) do
    chef_nodes.detect {|n| n.name == 'box02' }
  end

  let(:linode_chef_node) do
    chef_nodes.detect {|n| n.name == 'box03' }
  end

  let(:chef_nodes) do
    Dir['spec/data/*.json'].map do |node_json|
      Chef::Node.json_create(JSON.parse(IO.read(node_json)))
    end
  end

  let(:nodes) do
    chef_indexer = Lita::Handlers::Enhance::ChefIndexer.new(redis, {})
    chef_nodes.map do |chef_node| 
      node = chef_indexer.node_from_chef_node(chef_node)
      node.store!(redis)
      node
    end
  end

  let(:nodes_and_chef_nodes) do
    nodes.zip(chef_nodes)
  end
end

RSpec.shared_context 'redis' do
  let(:redis) { Redis.new }

  before do
    redis.flushdb
  end
end

RSpec.shared_context 'indexed' do
  include_context 'mocks'
  include_context 'redis'

  let(:chef_indexer) { Lita::Handlers::Enhance::ChefIndexer.new(redis, {}) }

  before do
    chef_nodes.each do |chef_node|
      chef_indexer.index_chef_node(chef_node)
    end
  end
end
