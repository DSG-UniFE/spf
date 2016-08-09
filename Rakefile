require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  # so that we can use "require 'spec/spec_helper'" and 
  # "require 'spec/support/...'" in the test files
  t.libs << File.dirname(__FILE__)

  t.test_files = FileList['spec/**/*_spec.rb']
  t.verbose = true
end

Rake::TestTask.new(:bench) do |t|
  # so that we can use "require 'spec/spec_helper'" and 
  # "require 'spec/support/...'" in the test files
  t.libs << File.dirname(__FILE__)
  # t.libs = %w(lib test)

  t.test_files = FileList['spec/performance/**/*_benchmark.rb']
  t.verbose = true
end

task :default => :test
