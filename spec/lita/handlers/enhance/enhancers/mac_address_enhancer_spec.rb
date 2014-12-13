require "spec_helper"

describe Lita::Handlers::Enhance::MacAddressEnhancer do
  include_context 'mocks'
  include_context 'redis'

  let(:enhancer) { Lita::Handlers::Enhance::MacAddressEnhancer.new(redis) }

  before do
    nodes_and_chef_nodes.each do |node, chef_node|
      enhancer.index(chef_node, node)
    end
  end

  it 'should enhance a string with MAC addresses in it' do
    message = 'before 22:00:0A:FE:4A:79 F2:3C:91:56:A2:00 after'
    enhancer.enhance!(message, 1)
    expect(message).to eq('before *box01* *box03* after')
  end

  it 'should return a custom response for to_s' do
    expect(enhancer.to_s).to match /MAC addresses indexed/
  end
end

