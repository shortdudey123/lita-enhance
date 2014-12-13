require "spec_helper"

describe Lita::Handlers::Enhance::InstanceIdEnhancer do
  include_context 'mocks'
  include_context 'redis'

  let(:enhancer) { Lita::Handlers::Enhance::InstanceIdEnhancer.new(redis) }

  before do
    nodes_and_chef_nodes.each do |node, chef_node|
      enhancer.index(chef_node, node)
    end
  end

  it 'should enhance a string with EC2 instance IDs in it' do
    message = 'before i-fe4cddcb i-f4ff6aff after'
    enhancer.enhance!(message, 1)
    expect(message).to eq('before *box01* *box02* after')
  end
end
