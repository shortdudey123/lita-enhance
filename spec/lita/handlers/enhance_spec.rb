require "spec_helper"

describe Lita::Handlers::Enhance, lita_handler: true do
  include_context 'indexed'

  before { allow(described_class).to receive(:new).and_return(subject) }

  # Make sure that we are indexing into the same Redis namespace that the handler uses.
  let(:redis) { subject.redis }

  let(:alice) { Lita::User.create('2', name: 'Alice') }

  it { is_expected.to route_command('refresh enhance').to(:refresh) }
  it { is_expected.to route_command('enhance stats').to(:stats) }

  it { is_expected.to route_command('enhance 127.0.0.1').to(:enhance) }
  it { is_expected.to route_command("enhance lvl:1 blah\nblah").to(:enhance) }
  it { is_expected.to route_command('enhance').to(:enhance) }
  it { is_expected.to route_command('enhance lvl:2').to(:enhance) }

  it 'should show stats about itself' do
    send_command('enhance stats')
    expect(replies.last).to include('Last refreshed')
  end

  it 'should be possible to force a refresh of the index' do
    expect(subject).to receive(:lock_and_refresh_index)

    send_command('refresh enhance')

    # Give the timer a chance to run
    sleep(0.5)

    expect(replies).to include('Will refresh enhance index...')
    expect(replies).to include('Refreshed enhance index')
  end

  it 'should require a message to enhance' do
    send_command('enhance')
    expect(replies).to include('I need a string to enhance')
  end

  it 'should enhance IP addresses' do
    send_command('enhance 54.214.188.37')
    expect(replies).to include('*box01*')
  end

  it 'should return text that is the same format with enhancements applied' do
    send_command('enhance Finished hinted handoff of 8826 rows to endpoint /10.254.74.121')
    expect(replies).to include('Finished hinted handoff of 8826 rows to endpoint /*box01*')
  end

  it 'should allow increasing the level of enhancement' do
    send_command('enhance lvl:2 54.214.188.37')
    expect(replies).to include('*box01 (us-west-2b)*')
  end

  it 'should return an error when the enhancement level is too high' do
    send_command('enhance lvl:9 54.214.188.37')
    expect(replies).to include('Cannot enhance above level 5')
  end

  it 'should allow implicitly enhancing the last enhanced message at a higher level' do
    # Messages are enhanced at level 1 by default
    send_command('enhance 54.214.188.37')
    expect(replies).to include('*box01*')

    # Now we're re-enhancing at level 2
    send_command('enhance')
    expect(replies).to include('*box01 (us-west-2b)*')
  end

  it 'should allow implicitly enhancing the last message at an explicit level' do
    # If we explicitly enhance at level 3, the next level would be 4
    send_command('enhance lvl:3 54.214.188.37')
    expect(replies).to include('*box01 (us-west-2b, _default)*')

    # A user can choose an explicit level....
    send_command('enhance lvl:1')
    expect(replies).to include('*box01*')

    # ... which then is retained for the next implicit enhancement
    send_command('enhance')
    expect(replies).to include('*box01 (us-west-2b)*')
  end

  it 'implicit messages are remembered per-source' do
    send_command('enhance test user 54.214.188.37')
    expect(replies).to include('test user *box01*')

    send_command('enhance alice 54.214.188.37', as: alice)
    expect(replies).to include('alice *box01*')

    send_command('enhance lvl:3')
    expect(replies).to include('test user *box01 (us-west-2b, _default)*')

    send_command('enhance', as: alice)
    expect(replies).to include('alice *box01 (us-west-2b)*')
  end

  it 'should call out when nothing could be enhanced' do
    send_command('enhance bubbles')
    expect(replies).to include('I could not find anything to enhance')
  end

  describe 'under Slack' do
    before do
      allow_any_instance_of(Lita::TemplateResolver).to receive(:adapter_name).and_return(:slack)
    end

    it 'should mark success using an emoji' do
      expect(subject).to receive(:lock_and_refresh_index)

      send_command('refresh enhance')

      # Give the timer a chance to run
      sleep(0.5)

      expect(replies).to include('Will refresh enhance index...')
      expect(replies).to include(':successful: Refreshed enhance index')
    end

    it 'mark failure using an emoji' do
      send_command('enhance')
      expect(replies).to include(':failed: I need a string to enhance')
    end

    it 'should use backticks to render mono text' do
      send_command('enhance 54.214.188.37')
      expect(replies).to include('```*box01*```')
    end

    it 'should use emoji to call out when nothing was found to enhance' do
      send_command('enhance bubbles')
      expect(replies).to include(':nothingtodohere: I could not find anything to enhance')
    end
  end

  describe 'under HipChat' do
    before do
      allow_any_instance_of(Lita::TemplateResolver).to receive(:adapter_name).and_return(:hipchat)
    end

    it 'should mark success using an emoji' do
      expect(subject).to receive(:lock_and_refresh_index)

      send_command('refresh enhance')

      # Give the timer a chance to run
      sleep(0.5)

      expect(replies).to include('Will refresh enhance index...')
      expect(replies).to include('(successful) Refreshed enhance index')
    end

    it 'mark failure using an emoji' do
      send_command('enhance')
      expect(replies).to include('(failed) I need a string to enhance')
    end

    it 'should use /quote to render mono text' do
      send_command('enhance 54.214.188.37')
      expect(replies).to include('/quote *box01*')
    end

    it 'should use emoji to call out when nothing was found to enhance' do
      send_command('enhance bubbles')
      expect(replies).to include('(nothingtodohere) I could not find anything to enhance')
    end
  end
end
