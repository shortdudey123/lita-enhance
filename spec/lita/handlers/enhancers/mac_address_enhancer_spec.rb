require "spec_helper"

describe Lita::Handlers::Enhance::MacAddressEnhancer do
  include_context 'mocks'

  let(:enhancer) { Lita::Handlers::Enhance::MacAddressEnhancer.new }

  before do
    chef_nodes.each do |chef_node|
      node = Lita::Handlers::Enhance::Node.from_chef_node(chef_node)
      enhancer.index(chef_node, node)
    end
  end

  it 'should enhance a string with MAC addresses in it' do
    message = 'before 22:00:0A:FE:4A:79 F2:3C:91:56:A2:00 after'
    enhancer.enhance!(message, 1)
    expect(message).to eq('before *box01* *box03* after')
  end
end

