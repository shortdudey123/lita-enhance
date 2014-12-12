require "spec_helper"

describe Lita::Handlers::Enhance, lita_handler: true do
  it { routes_command('refresh enhance').to(:refresh) }
  it { routes_command('enhance stats').to(:stats) }

  it { routes_command('enhance 127.0.0.1').to(:enhance) }
  it { routes_command("enhance lvl:1 blah\nblah").to(:enhance) }
  it { routes_command("enhance").to(:enhance) }
  it { routes_command("enhance lvl:2").to(:enhance) }
end
