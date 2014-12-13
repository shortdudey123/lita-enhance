require "spec_helper"

require 'lita/handlers/enhance/node_index'

describe Lita::Handlers::Enhance::NodeIndex do
  include_context 'mocks'
  include_context 'redis'

  let(:index) { Lita::Handlers::Enhance::NodeIndex.new(redis, 'fqdn') }
  let(:node) { nodes.first }

  it 'should be able to add a node to the index' do
    index.add('127.0.0.1', node)
  end

  it 'should be able to find a node in the index' do
    index.add('127.0.0.1', node)
    new_node = index.search('127.0.0.1')
    expect(new_node.name).to eq(node.name)
  end

  it 'should return nil if no node is found in the index' do
    expect(index.search('127.0.0.5')).to be_nil
  end

  it 'should be able to return its size' do
    expect(index.size).to eq(0)
    nodes.each do |node|
      index.add(node.name, node)
    end
    expect(index.size).to eq(3)
  end
end
