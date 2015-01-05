require "spec_helper"

require 'lita/handlers/enhance/enhancer_example'

describe Lita::Handlers::Enhance::HostnameEnhancer do
  include_context 'indexed'

  let(:enhancer) { Lita::Handlers::Enhance::HostnameEnhancer.new(redis) }
  let(:sub_klass) { Lita::Handlers::Enhance::Substitution }

  it_should_behave_like 'an enhancer'

  it 'should enhance a string with an EC2 public hostname in it' do
    message = 'before ec2-54-214-188-37.us-west-2.compute.amazonaws.com after'
    substitutions = enhancer.enhance!(message, 1)
    expect(substitutions).to eq [sub_klass.new(7...56, '*box01*')]
  end

  it 'should enhance a string with an EC2 short public hostname in it' do
    message = 'before ec2-54-214-188-37 after'
    substitutions = enhancer.enhance!(message, 1)
    expect(substitutions).to eq [sub_klass.new(7...24, '*box01*')]
  end

  it 'should enhance a string with an EC2 localhost hostname in it' do
    message = 'before ip-10-254-74-121.us-west-2.compute.internal after'
    substitutions = enhancer.enhance!(message, 1)
    expect(substitutions).to eq [sub_klass.new(7...50, '*box01*')]
  end

  it 'should enhance a string with an EC2 localhost hostname in it' do
    message = 'before ip-10-254-74-121 after'
    substitutions = enhancer.enhance!(message, 1)
    expect(substitutions).to eq [sub_klass.new(7...23, '*box01*')]
  end

  it 'should enhance a string with a custom long hostname in it' do
    message = 'before box01.example.com after'
    substitutions = enhancer.enhance!(message, 1)
    expect(substitutions).to eq [sub_klass.new(7...24, '*box01*')]
  end

  it 'should enhance a string with a custom short hostname in it' do
    message = 'before box01 after'
    substitutions = enhancer.enhance!(message, 1)
    expect(substitutions).to eq [sub_klass.new(7...12, '*box01*')]
  end

  it 'should not enhance a string with an unknown hostname' do
    message = 'foo.bar.com'
    substitutions = enhancer.enhance!(message, 1)
    expect(substitutions).to be_empty
  end

  it 'should return a custom response to to_s' do
    expect(enhancer.to_s).to match /short hostnames.*long hostnames indexed/
  end
end
