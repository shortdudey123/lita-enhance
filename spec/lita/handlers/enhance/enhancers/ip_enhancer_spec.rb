require "spec_helper"

require 'lita/handlers/enhance/enhancer_example'

describe Lita::Handlers::Enhance::IpEnhancer do
  include_context 'mocks'
  include_context 'redis'

  let(:enhancer) { Lita::Handlers::Enhance::IpEnhancer.new(redis) }
  let(:sub_klass) { Lita::Handlers::Enhance::Substitution }

  before do
    nodes_and_chef_nodes.each do |node, chef_node|
      enhancer.index(chef_node, node)
    end
  end

  it_should_behave_like 'an enhancer'

  it 'should enhance a string with EC2 external IPs in it' do
    message = 'before 54.214.188.37 184.169.229.1 after'
    substitutions = enhancer.enhance!(message, 1)
    expect(substitutions).to contain_exactly(
      sub_klass.new(7...20, '*box01*'),
      sub_klass.new(21...34, '*box02*')
    )
  end

  it 'should enhance a string with EC internal IPs in it' do
    message = 'before 10.254.74.121 10.196.75.1 after'
    substitutions = enhancer.enhance!(message, 1)
    expect(substitutions).to contain_exactly(
      sub_klass.new(7...20, '*box01*'),
      sub_klass.new(21...32, '*box02*')
    )
  end

  it 'should enhance a string with Linode IPs in it' do
    message = 'before 192.155.85.2 after'
    substitutions = enhancer.enhance!(message, 1)
    expect(substitutions).to contain_exactly(
      sub_klass.new(7...19, '*box03*')
    )
  end

  it 'should not enhance an unrecognized IP' do
    message = '127.0.0.1'
    substitutions = enhancer.enhance!(message, 1)
    expect(substitutions).to be_empty
  end

  it 'should return a custom response to to_s' do
    expect(enhancer.to_s).to match /IPs indexed/
  end
end
