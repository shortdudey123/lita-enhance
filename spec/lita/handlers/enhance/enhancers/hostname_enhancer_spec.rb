require "spec_helper"

describe Lita::Handlers::Enhance::HostnameEnhancer do
  include_context 'mocks'

  let(:enhancer) { Lita::Handlers::Enhance::HostnameEnhancer.new }

  before do
    chef_nodes.each do |chef_node|
      node = Lita::Handlers::Enhance::Node.from_chef_node(chef_node)
      enhancer.index(chef_node, node)
    end
  end

  it 'should enhance a string with an EC2 public hostname in it' do
    message = 'before ec2-54-214-188-37.us-west-2.compute.amazonaws.com after'
    enhancer.enhance!(message, 1)
    expect(message).to eq('before *box01* after')
  end

  it 'should enhance a string with an EC2 short public hostname in it' do
    message = 'before ec2-54-214-188-37 after'
    enhancer.enhance!(message, 1)
    expect(message).to eq('before *box01* after')
  end

  it 'should enhance a string with an EC2 localhost hostname in it' do
    message = 'before ip-10-254-74-121.us-west-2.compute.internal after'
    enhancer.enhance!(message, 1)
    expect(message).to eq('before *box01* after')
  end

  it 'should enhance a string with an EC2 localhost hostname in it' do
    message = 'before ip-10-254-74-121 after'
    enhancer.enhance!(message, 1)
    expect(message).to eq('before *box01* after')
  end

  it 'should enhance a string with a custom long hostname in it' do
    message = 'before box01.example.com after'
    enhancer.enhance!(message, 1)
    expect(message).to eq('before *box01* after')
  end

  it 'should enhance a string with a custom short hostname in it' do
    message = 'before box01 after'
    enhancer.enhance!(message, 1)
    expect(message).to eq('before *box01* after')
  end
end
