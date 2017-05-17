require "spec_helper"

require 'lita/handlers/enhance/enhancer_example'

describe Lita::Handlers::Enhance::InstanceIdEnhancer do
  include_context 'indexed'

  let(:enhancer) { Lita::Handlers::Enhance::InstanceIdEnhancer.new(redis) }
  let(:sub_klass) { Lita::Handlers::Enhance::Substitution }

  it_should_behave_like 'an enhancer'

  it 'should enhance a string with EC2 instance IDs in it' do
    message = 'before i-fe4cddcb i-f4ff6aff after'
    substitutions = enhancer.enhance!(message, 1)
    expect(substitutions).to contain_exactly(
      sub_klass.new(7...17, '*box01*'),
      sub_klass.new(18...28, '*box02*')
    )
  end

  it 'should enhance a short and long EC2 instance ID that overlap' do
    message = 'i-f4ff6aff i-f4ff6afff4ff6afff'
    substitutions = enhancer.enhance!(message, 1)
    expect(substitutions).to contain_exactly(
      sub_klass.new(0...10, '*box02*'),
      sub_klass.new(11...30, '*box04*')
    )
  end

  it 'should not enhance an unrecognized EC2 instance ID' do
    message = 'i-f00bac12'
    substitutions = enhancer.enhance!(message, 1)
    expect(substitutions).to be_empty
  end

  it 'should return a custom response to to_s' do
    expect(enhancer.to_s).to match /instance IDs indexed/
  end
end
