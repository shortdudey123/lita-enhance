require "lita-enhance"
require "lita/rspec"

require 'pry'

RSpec.shared_context 'mocks' do
  include_context 'redis'

  def spec_data(file_name)
    File.read(File.expand_path("../data/#{file_name}", __FILE__))
  end

  let(:west2_chef_node) do
    Chef::Node.json_create(JSON.parse(spec_data('box01.json')))
  end

  let(:west1_chef_node) do
    Chef::Node.json_create(JSON.parse(spec_data('box02.json')))
  end

  let(:linode_chef_node) do
    Chef::Node.json_create(JSON.parse(spec_data('box03.json')))
  end

  let(:chef_nodes) do
    [west2_chef_node, west1_chef_node, linode_chef_node]
  end

  let(:nodes) do
    chef_nodes.map do |chef_node| 
      node = Lita::Handlers::Enhance::Node.from_chef_node(chef_node)
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
