Gem::Specification.new do |spec|
  spec.name          = "lita-enhance"
  spec.version       = "0.0.1"
  spec.authors       = ["Doug Barth"]
  spec.email         = ["doug@pagerduty.com"]
  spec.description   = %q{A Lita handler that enhances text by replacing opaque identifiers with Chef node names}
  spec.summary       = %q{A Lita handler that enhances text by replacing opaque identifiers with Chef node names}
  spec.homepage      = "TODO: Add a homepage"
  spec.license       = "MIT"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 3.1"
  spec.add_runtime_dependency "chef", ">= 11.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.0.0.beta2"
end
