# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vignette/version'

Gem::Specification.new do |gem|
  gem.name          = "vignette"
  gem.version       = Vignette::VERSION
  gem.authors       = ["Geoff Hayes"]
  gem.email         = ["geoff@safeshepherd.com"]
  gem.description   = %q{Simple, effective A/b testing made easy.}
  gem.summary       = %q{With a few simple features, get A/b testing up in your application.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
