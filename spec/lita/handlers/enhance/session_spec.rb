require 'spec_helper'

describe Lita::Handlers::Enhance::Session do
  include_context 'indexed'

  let(:session) { Lita::Handlers::Enhance::Session.new(redis, 'foo', 30) }

  it 'should return nil for last_level and last_message if no message has been enhanced' do
    expect(session.last_message).to be_nil
    expect(session.last_level).to be_nil
  end

  it 'should return the last message and level after enhancing a message' do
    session.enhance!('hello world', 2)
    expect(session.last_message).to eq('hello world')
    expect(session.last_level).to eq(2)
  end

  it 'should edit the message to enhance it' do
    message = 'hello world box01'
    session.enhance!(message, 1)
    expect(message).to eq('hello world *box01*')
  end

  it 'should enhance at the supplied level' do
    message = 'hello world box01'
    session.enhance!(message, 2)
    expect(message).to eq('hello world *box01 (us-west-2b)*')
  end

  it 'should should take care to not double enhance text', focus: true do
    message = 'hello world 10.254.74.122'
    session.enhance!(message, 2)
    expect(message).to eq('hello world *stg-web01 (us-west-2b)*')
  end

  it 'should be able to enhance multiple items' do
    message = 'box01 box02'
    session.enhance!(message, 2)
    expect(message).to eq('*box01 (us-west-2b)* *box02 (us-west-1c)*')
  end

  it 'should be able to correctly apply substitutions that result in shorter text' do
    message = 'before 22:00:0A:FE:4A:79 F2:3C:91:56:A2:00 after'
    session.enhance!(message, 1)
    expect(message).to eq('before *box01* *box03* after')
  end
end
