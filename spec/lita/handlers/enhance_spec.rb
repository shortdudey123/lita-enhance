require "spec_helper"

describe Lita::Handlers::Enhance, lita_handler: true do
  it { routes_command('refresh enhance').to(:refresh) }
  it { routes_command('enhance stats').to(:stats) }

  it { routes_command('enhance 127.0.0.1').to(:enhance) }
  it { routes_command("enhance lvl:1 blah\nblah").to(:enhance) }
  it { routes_command("enhance").to(:enhance) }
  it { routes_command("enhance lvl:2").to(:enhance) }

  it 'should show stats about itself' do
    send_command('enhance stats')
    expect(replies.last).to include('Last refreshed')
  end

  it 'should be possible to force a refresh of the index' do
    expect(subject).to receive(:lock_and_refresh_index)

    send_command('refresh enhance')

    # Give the timer a chance to run
    Thread.pass

    expect(replies).to include('Will refresh enhance index...')
    expect(replies).to include('(successful) Refreshed enhance index')
  end

  it 'should require a message to enhance' do
    send_command('enhance')
    expect(replies).to include('(failed) I need a string to enhance')
  end
end
