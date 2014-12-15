require "spec_helper"

describe Lita::Handlers::Enhance::Node do
  include_context 'mocks'
  include_context 'redis'

  let(:node) { Lita::Handlers::Enhance::Node.from_chef_node(west2_chef_node) }

  it 'should be able to create a node from a Chef::Node' do
    expect(node.name).to eq('box01')
    expect(node.dc).to eq('us-west-2b')
    expect(node.environment).to eq('_default')
    expect(node.fqdn).to eq('box01.example.com')
    expect(node.last_seen_at.to_f).to be_within(5).of(Time.now.to_f)
  end

  it "should be able to save it's state in a JSON blob" do
    node_json = node.as_json
    expect(node_json).to include(
      name: 'box01',
      dc: 'us-west-2b',
      environment: '_default',
      fqdn: 'box01.example.com'
    )
    expect(node_json[:last_seen_at]).to_not be_nil
  end

  it "should be able to store and load itself" do
    node.store!(redis)

    new_node = Lita::Handlers::Enhance::Node.load(redis, 'box01')
    expect(new_node).to_not be_nil
    expect(new_node.name).to eq(node.name)
    expect(new_node.last_seen_at).to be_kind_of(Time)
  end

  it 'should be able to render itself at differing levels of detail' do
    expect(node.render(1)).to eq('box01')
    expect(node.render(2)).to eq('box01 (us-west-2b)')
    expect(node.render(3)).to eq('box01 (us-west-2b, _default)')
    expect(node.render(4)).to eq('box01.example.com (us-west-2b, _default)')
  end

  it 'should know if it is old' do
    expect(node.old?).to be(false)

    node.last_seen_at = Time.now - 24 * 60 * 60
    expect(node.old?).to be(true)
  end
end
