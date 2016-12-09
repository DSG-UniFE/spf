require 'rake/testtask'

require 'open-uri'
require 'openssl'

# Setup absolute path for jars directory
JAR_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'jars'))

MAVEN_DEPS = {
  'https://dl.bintray.com/ihmcrobotics/maven-vendor' => [
    'us.ihmc.thirdparty.org.opencv:opencv:3.1.0',
    # opencv has the following dependencies. Since our Java dependency
    # retrieval code does not support automatic discovery of dependencies
    # (which would require downloading and processing the POM file for each
    # archive), we need to make these dependencies explicit.
    'us.ihmc.thirdparty.org.opencv:opencv-java-natives-linux64:3.1.0',
    'us.ihmc.thirdparty.org.opencv:opencv-java-natives-osx:3.1.0',
    'us.ihmc.thirdparty.org.opencv:opencv-java-natives-win64:3.1.0',
  ],
  'http://central.maven.org/maven2' => [
    'cryptix:cryptix:3.2.0',
    'org.bouncycastle:bcprov-jdk15on:1.55',
  ],
  'https://maven.tacc.utexas.edu/nexus/content/repositories/public' => [
    'com.claymoresystems:puretls:1.1'
  ]
}

directory JAR_DIR

desc 'Get jar dependencies'
task :get_jars => [ JAR_DIR ] do

  processed_dependencies = []

  MAVEN_DEPS.each do |repo_url,dependencies|

    dependencies.each do |dependency|
      pkg_path, pkg_name, pkg_version = dependency.split(':')
      pkg_path.gsub!(/\./, '/')

      jar_file = "#{pkg_name}-#{pkg_version}.jar"
      jar_url  = "#{repo_url}/#{pkg_path}/#{pkg_name}/#{pkg_version}/#{jar_file}"
      destination_file = File.join(JAR_DIR, jar_file)

      puts "Processing #{jar_file} ..."
      processed_dependencies << jar_file

      # Don't download archive if already present in JAR_DIR
      if File.exists?(destination_file)
        puts "Nothing to do. Archive is already present in jars directory."
      else
        puts "Retrieving archive from #{jar_url}"
        File.write(destination_file, open(jar_url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read)
      end
    end

  end

  # Remove obsolete archives from JAR_DIR
  removed = 0
  Dir.entries(JAR_DIR) do |f|
    # Ignore directories (there shouldn't be any, but you never know...)
    next if File.directory? f

    # f is in processed_dependencies, keep it!
    next if processed_dependencies.include? f

    # If we arrived here, f is an obsolete file that needs to be removed
    FileUtils.rm(File.join(JAR_DIR, f)) 
    puts 'Removing obsolete archives from jars directory.' if removed == 0
    removed += 1
  end
end


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
