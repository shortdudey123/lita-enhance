require "spec_helper"

require 'lita/handlers/enhance/enhancer_example'

describe Lita::Handlers::Enhance::HostnameEnhancer do
  include_context 'mocks'
  include_context 'redis'

  let(:enhancer) { Lita::Handlers::Enhance::HostnameEnhancer.new(redis) }

  before do
    nodes_and_chef_nodes.each do |node, chef_node|
      enhancer.index(chef_node, node)
    end
  end

  it_should_behave_like 'an enhancer'

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

  it 'should return a custom response to to_s' do
    expect(enhancer.to_s).to match /short hostnames.*long hostnames indexed/
  end
end
