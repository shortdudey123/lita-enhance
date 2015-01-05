require "spec_helper"

require 'lita/handlers/enhance/enhancer_example'

describe Lita::Handlers::Enhance::MacAddressEnhancer do
  include_context 'indexed'

  let(:enhancer) { Lita::Handlers::Enhance::MacAddressEnhancer.new(redis) }
  let(:sub_klass) { Lita::Handlers::Enhance::Substitution }

  it_should_behave_like 'an enhancer'

  it 'should enhance a string with MAC addresses in it' do
    message = 'before 22:00:0A:FE:4A:79 F2:3C:91:56:A2:00 after'
    substitutions = enhancer.enhance!(message, 1)
    expect(substitutions).to contain_exactly(
      sub_klass.new(7...24, '*box01*'),
      sub_klass.new(25...42, '*box03*')
    )
  end

  it 'should not enhance an unrecognized MAC address' do
    message = '00:00:00:00:00:00'
    substitutions = enhancer.enhance!(message, 1)
    expect(substitutions).to be_empty
  end

  it 'should return a custom response for to_s' do
    expect(enhancer.to_s).to match /MAC addresses indexed/
  end
end

