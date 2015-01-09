require "spec_helper"

describe Lita::Handlers::Enhance::Node do
  include_context 'mocks'
  include_context 'redis'

  let(:node) do
    described_class.new.tap do |n|
      n.name = 'box01'
      n.dc = 'us-west-2b'
      n.environment = '_default'
      n.fqdn = 'box01.example.com'
      n.last_seen_at = Time.now
    end
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
    expect(node.render(4)).to match /box01 \(us-west-2b, _default, last seen .*\)/
    expect(node.render(5)).to match /box01\.example\.com \(us-west-2b, _default, last seen .*\)/
  end

  it 'should know if it is old' do
    expect(node.old?).to be(false)

    node.last_seen_at = Time.now - 24 * 60 * 60
    expect(node.old?).to be(true)
  end
end
