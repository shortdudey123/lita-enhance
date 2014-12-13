require "spec_helper"

describe Lita::Handlers::Enhance::Node do
  include_context 'mocks'

  let(:redis) { Redis.new }
  let(:node) { Lita::Handlers::Enhance::Node.from_chef_node(west2_chef_node) }

  before do
    redis.flushdb
  end

  it 'should be able to create a node from a Chef::Node' do
    expect(node.name).to eq('box01')
    expect(node.dc).to eq('us-west-2b')
    expect(node.environment).to eq('_default')
    expect(node.fqdn).to eq('box01.example.com')
  end

  it "should be able to save it's state in a JSON blob" do
    expect(node.as_json).to eq(
      name: 'box01',
      dc: 'us-west-2b',
      environment: '_default',
      fqdn: 'box01.example.com'
    )
  end

  it "should be able to store and load itself" do
    node.store!(redis)

    new_node = Lita::Handlers::Enhance::Node.load(redis, 'box01')
    expect(new_node).to_not be_nil
    expect(new_node.name).to eq(node.name)
  end
end
