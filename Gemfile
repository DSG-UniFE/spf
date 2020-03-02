source 'https://rubygems.org'

gem 'concurrent-ruby', '~> 1.0.0', require: 'concurrent'
gem 'timers', '~> 4.1.0'
gem 'rest-client', '~> 2.0.0'
gem 'chromaprint', '~> 0.0.2'
gem 'waveinfo', '~> 0.0.4'
gem 'logger-colors', '~> 1.0'
gem 'geocoder'
gem 'sinatra'

# for MQTT Bus
gem 'mqtt'

group :development do
  gem 'rake', '>= 12.3.3'

  # to generate documentation
  gem 'yard', '~> 0.9.5', require: false

  # for code quality checking
  gem 'rubocop', '~> 0.49.0', require: false

  # for graphic interface
  gem 'shoes', '>= 4.0.0.pre6'
end

group :test do
  # to add support for context blocks
  gem 'minitest-spec-context', '~> 0.0.3'

  # for improved reporting
  gem 'minitest-reporters', '~> 1.1.7'
end
