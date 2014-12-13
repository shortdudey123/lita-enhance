require "spec_helper"

describe Lita::Handlers::Enhance::IpEnhancer do
  include_context 'mocks'

  let(:enhancer) { Lita::Handlers::Enhance::IpEnhancer.new }

  before do
    chef_nodes.each do |chef_node|
      node = Lita::Handlers::Enhance::Node.from_chef_node(chef_node)
      enhancer.index(chef_node, node)
    end
  end

  it 'should enhance a string with EC2 external IPs in it' do
    message = 'before 54.214.188.37 184.169.229.1 after'
    enhancer.enhance!(message, 1)
    expect(message).to eq('before *box01* *box02* after')
  end

  it 'should enhance a string with EC internal IPs in it' do
    message = 'before 10.254.74.121 10.196.75.1 after'
    enhancer.enhance!(message, 1)
    expect(message).to eq('before *box01* *box02* after')
  end

  it 'should enhance a string with Linode IPs in it' do
    message = 'before 192.155.85.2 after'
    enhancer.enhance!(message, 1)
    expect(message).to eq('before *box03* after')
  end
end
