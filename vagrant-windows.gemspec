# -*- encoding: utf-8 -*-
require File.expand_path('../lib/vagrant-windows/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Paul Morton"]
  gem.email         = ["pmorton@biaprotect.com"]
  gem.description   = %q{Windows Guest Support for Vagrant}
  gem.summary       = %q{A small gem that adds windows guest support to vagrant, uses WinRM as the Communication Channel}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "vagrant-windows"
  gem.require_paths = ["lib"]
  gem.version       = VagrantWindows::VERSION

  gem.add_runtime_dependency "winrm", "~> 1.1.1"
  gem.add_runtime_dependency 'highline'
end