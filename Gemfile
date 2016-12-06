source 'https://rubygems.org'

ruby '2.3.0', engine: 'jruby', engine_version: '9.1.2.0'

gem 'concurrent-ruby', '~> 1.0.0'
gem 'timers', '~> 4.1.0'
gem 'geokdtree', '~> 0.2.1'

group :development do
  gem 'rake', '~> 11.2.2'

  # to generate documentation
  gem 'yard', '~> 0.9.5', require: false

  # for code quality checking
  gem 'rubocop', '~> 0.42.0', require: false

  # for graphic interface
  gem install shoes --pre
end

group :test do
  # to add support for context blocks
  gem 'minitest-spec-context', '~> 0.0.3'

  # for improved reporting
  gem 'minitest-reporters', '~> 1.1.7'
end
