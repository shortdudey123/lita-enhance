require 'spec_helper'

RSpec.shared_examples 'an enhancer' do
  it 'should be able to render a node' do
    expect(enhancer.render(nodes.first, 1)).to eq('*box01*')
    expect(enhancer.render(nodes.first, 2)).to eq('*box01 (us-west-2b)*')
  end

  it 'should render an old node slightly differently' do
    node = nodes.first
    node.last_seen_at = Time.now - 24 * 60 * 60

    expect(enhancer.render(node, 1)).to eq('?box01?')
    expect(enhancer.render(node, 2)).to eq('?box01 (us-west-2b)?')
  end
end
