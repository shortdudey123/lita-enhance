require "spec_helper"

describe Lita::Handlers::Enhance::ChefIndexer do
  include_context 'mocks'
  include_context 'redis'

  let(:indexer) { described_class.new(redis, {}) }

  let(:config) { double('Lita::Configuration', handlers: double(enhance: double(size_attribute: 'base.size'))) }

  it 'should be able to create Node from a Chef::Node' do
    node = indexer.node_from_chef_node(west2_chef_node)

    expect(node.name).to eq('box01')
    expect(node.dc).to eq('us-west-2b')
    expect(node.environment).to eq('_default')
    expect(node.roles).to eq(["webapp", "base"])
    expect(node.fqdn).to eq('box01.example.com')
    expect(node.last_seen_at.to_f).to be_within(5).of(Time.now.to_f)
  end

  it 'should be able to create Node from a Chef::Node with a custom size_attribute' do
    allow(Lita).to receive(:config) { config }
    node = indexer.node_from_chef_node(stg_web01)

    expect(node.name).to eq('web01')
    expect(node.dc).to eq('us-west-2b')
    expect(node.size).to eq('medium.memory')
    expect(node.environment).to eq('_default')
    expect(node.roles).to eq(["webapp", "base"])
    expect(node.fqdn).to eq('web01.example.com')
    expect(node.last_seen_at.to_f).to be_within(5).of(Time.now.to_f)
  end
end
