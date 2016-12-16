require 'rake/testtask'
require 'rake/clean'

require 'open-uri'
require 'openssl'

OPENCV_JAR_LOCATION = '/usr/share/java/opencv.jar'

# Setup absolute path for jars directory
JAR_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'jars'))

MAVEN_DEPS = {
  'http://central.maven.org/maven2' => [
    'cryptix:cryptix:3.2.0',
    'org.bouncycastle:bcprov-jdk15on:1.55',
  ],
  'https://maven.tacc.utexas.edu/nexus/content/repositories/public' => [
    'com.claymoresystems:puretls:1.1'
  ]
}

JAVA_SOURCES_DIR = File.join("src", "java")

DISSERVICE_SOURCE_DIR = File.join(JAVA_SOURCES_DIR, "disservice")
DISSERVICE_SOURCES = Rake::FileList[File.join(DISSERVICE_SOURCE_DIR, "**", "*.java")]
DISSERVICE_CLASSES = DISSERVICE_SOURCES.ext(".class")
DISSERVICE_JAR = File.join(JAR_DIR, "spf.jar")

SPF_SOURCE_DIR = File.join(JAVA_SOURCES_DIR, "spf")
SPF_SOURCES = Rake::FileList[File.join(SPF_SOURCE_DIR, "**", "*.java")]
SPF_CLASSES = SPF_SOURCES.ext(".class")
SPF_JAR = File.join(JAR_DIR, "disservice.jar")

CLEAN.include(DISSERVICE_CLASSES, SPF_CLASSES)

CLOBBER.include(Rake::FileList.new(DISSERVICE_JAR, SPF_JAR))

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
  Dir.foreach(JAR_DIR) do |f|
    # Ignore directories (there shouldn't be any, but you never know...)
    next if File.directory? File.join(JAR_DIR, f)

    # f is in processed_dependencies, keep it!
    next if processed_dependencies.include? f

    # If we arrived here, f is an obsolete file that needs to be removed
    FileUtils.rm(File.join(JAR_DIR, f))
    puts 'Removing obsolete archives from jars directory.' if removed == 0
    removed += 1
  end
end

desc 'Compile and create archive for SPF Java code'
file "#{JAR_DIR}/spf.jar" => SPF_SOURCES do
  orig_dir = Dir.pwd
  Dir.chdir(SPF_SOURCE_DIR)
  sh "javac -cp '#{JAR_DIR}/*' -cp '#{OPENCV_JAR_LOCATION}' #{Dir[File.join('**', '*.java')].join(' ')}"
  sh "jar cvf spf.jar #{Dir[File.join('**', '*.class')].join(' ')}"
  Dir.chdir(orig_dir)
  FileUtils.mv(File.join(SPF_SOURCE_DIR, "spf.jar"), JAR_DIR)
end

desc 'Compile and create archive for Disservice Java code'
file "#{JAR_DIR}/disservice.jar" => DISSERVICE_SOURCES do
  orig_dir = Dir.pwd
  Dir.chdir(DISSERVICE_SOURCE_DIR)
  # sh "javac -Xlint:unchecked -cp '#{JAR_DIR}/*' #{Dir['us/**/*.java'].join(' ')}"
  sh "javac -Xlint:unchecked -cp '#{JAR_DIR}/*' #{Dir[File.join('**', '*.java')].join(' ')}"
  # sh "jar cvf disservice.jar #{Dir['us/**/*.class'].join(' ')}"
  sh "jar cvf disservice.jar #{Dir[File.join('**', '*.class')].join(' ')}"
  Dir.chdir(orig_dir)
  FileUtils.mv(File.join(DISSERVICE_SOURCE_DIR, "disservice.jar"), JAR_DIR)
end

# task :all_jars => [ :get_jars, :prepare_opencv, "#{JAR_DIR}/spf.jar", "#{JAR_DIR}/disservice.jar" ] do
task :all_jars => [ :get_jars, "#{JAR_DIR}/spf.jar", "#{JAR_DIR}/disservice.jar" ] do
end

SPF_RUBY_SOURCE_PATHS = [
  # add main project directory to list of source paths, so that we can use
  # "require 'spec/spec_helper'" and "require 'spec/support/...'" in the tests
  File.dirname(__FILE__),
  # base path of SPF source code
  File.join(File.dirname(__FILE__), 'src', 'ruby'),
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
