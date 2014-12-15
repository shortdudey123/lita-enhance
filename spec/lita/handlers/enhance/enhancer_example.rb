require 'spec_helper'

RSpec.shared_examples 'an enhancer' do
  it 'should be able to render a node' do
    expect(enhancer.render(nodes.first, '192.168.1.1', 1)).to eq('*box01*')
    expect(enhancer.render(nodes.first, '192.168.1.1', 2)).to eq('*box01 (us-west-2b)*')
  end

  it 'should return the original string if no node was found' do
    expect(enhancer.render(nil, '192.168.1.1', 1)).to eq('192.168.1.1')
    expect(enhancer.render(nil, '192.168.1.1', 2)).to eq('192.168.1.1')
  end

  it 'should render an old node slightly differently' do
    node = nodes.first
    node.last_seen_at = Time.now - 24 * 60 * 60

    expect(enhancer.render(node, '192.168.1.1', 1)).to eq('¿box01?')
    expect(enhancer.render(node, '192.168.1.1', 2)).to eq('¿box01 (us-west-2b)?')
  end
end
