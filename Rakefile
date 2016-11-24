require 'rake/testtask'

SPF_RUBY_SOURCE_PATHS = [ 
  # add main project directory to list of source paths, so that we can use
  # "require 'spec/spec_helper'" and "require 'spec/support/...'" in the tests
  File.dirname(__FILE__),
  # base path of common source code
  File.join(File.dirname(__FILE__), "common"),
  # base path of source code for the controller module
  File.join(File.dirname(__FILE__), "controller-module/src/main/ruby"),
  # base path of source code for the gateway module
  File.join(File.dirname(__FILE__), "gateway-module/src/main/ruby"),
]

Rake::TestTask.new(:test) do |t|
  t.libs = SPF_RUBY_SOURCE_PATHS

  t.test_files = FileList['spec/**/*_spec.rb']
  t.verbose = true
end

Rake::TestTask.new(:bench) do |t|
  t.libs = SPF_RUBY_SOURCE_PATHS

  t.test_files = FileList['spec/performance/**/*_benchmark.rb']
  t.verbose = true
end

task :default => :test
