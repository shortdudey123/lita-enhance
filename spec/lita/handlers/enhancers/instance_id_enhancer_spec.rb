require "spec_helper"

describe Lita::Handlers::Enhance::InstanceIdEnhancer do
  include_context 'mocks'

  let(:enhancer) { Lita::Handlers::Enhance::InstanceIdEnhancer.new }

  before do
    chef_nodes.each do |chef_node|
      node = Lita::Handlers::Enhance::Node.from_chef_node(chef_node)
      enhancer.index(chef_node, node)
    end
  end

  it 'should enhance a string with EC2 instance IDs in it' do
    message = 'before i-fe4cddcb i-f4ff6aff after'
    enhancer.enhance!(message, 1)
    expect(message).to eq('before *box01* *box02* after')
  end
end
