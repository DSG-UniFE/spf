# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spf/version'

Gem::Specification.new do |spec|
  spec.name          = 'spf-iot'
  spec.version       = SPF::VERSION
  spec.authors       = ['Mauro Tortonesi']
  spec.email         = ['mauro.tortonesi@unife.it']
  spec.summary       = %q{An SDN and VoI based solution for dynamic IoT applications in urban computing environments.}
  spec.description   = %q{Write a longer description. Optional.}
  spec.homepage      = 'https://github.com/mtortonesi/spf'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/).reject{|x| x == '.gitignore' }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'concurrent-ruby', '~> 0.9.1'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest-spec-context', '~> 0.0.3'
  spec.add_development_dependency 'minitest-reporters', '~> 1.1.7'

  # to generate the documentation
  spec.add_development_dependency 'yard', '~> 0.8.7.6'

  # for code quality checking
  spec.add_development_dependency 'rubocop', '~> 0.33.0'
end
