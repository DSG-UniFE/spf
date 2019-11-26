require 'rake/testtask'
require 'rake/clean'
require 'open-uri'
require 'openssl'

#require 'src/ruby/spf/common/extensions/thread_reporter'

if ARGV.length == 2
  OPENCV_JAR_LOCATION = ARGV[1]
  puts "OPENCV_JAR_LOCATION #{OPENCV_JAR_LOCATION}"
else
  OPENCV_JAR_LOCATION = '/usr/share/java/opencv.jar'
end

# Setup absolute path for jars directory
JAR_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'jars'))

MAVEN_DEPS = {
  'http://central.maven.org/maven2' => [
    #For OpenCV (local jar)
    ':opencv:401',
    #For DSPro
    'com.fasterxml.jackson.core:jackson-core:2.4.4',
    'com.fasterxml.jackson.core:jackson-databind:2.4.4',
    #For DisService
    'cryptix:cryptix:3.2.0',
    'org.bouncycastle:bcprov-jdk15on:1.55',
    #For Tesseract
    'net.sourceforge.tess4j:tess4j:3.2.0',
    'ch.qos.logback:logback-classic:1.1.8',
    'com.github.jai-imageio:jai-imageio-core:1.3.1',
    'commons-io:commons-io:2.5',
    'net.java.dev.jna:jna:4.2.1',
    'net.sourceforge.lept4j:lept4j:1.2.4',
    'org.ghost4j:ghost4j:1.0.1',
    'org.slf4j:slf4j-api:1.7.21',
    'org.slf4j:log4j-over-slf4j:1.7.21',
    'org.slf4j:jul-to-slf4j:1.7.21',
    'log4j:log4j:1.2.17',
    'ch.qos.logback:logback-core:1.1.7',
    'org.bytedeco:javacv-platform:1.5.1',
    'org.bytedeco:javacpp:1.5.1',
    'org.bytedeco:opencv:4.1.0-1.5.1',
    'org.bytedeco:ffmpeg:4.1.3-1.5.1',
    'org.bytedeco:videoinput:0.200-1.5.1',
  ],
  'https://maven.tacc.utexas.edu/nexus/content/repositories/public' => [
    'com.claymoresystems:puretls:1.1'
  ]
}

JAVA_SOURCES_DIR = File.join("src", "java")

# Load native utils file
LOADOPENCV_SOURCE_DIR = File.join(JAVA_SOURCES_DIR, "loadopencv")
LOADOPENCV_SOURCES = Rake::FileList[File.join(LOADOPENCV_SOURCE_DIR, "**", "*.java")]
LOADOPENCV_CLASSES = LOADOPENCV_SOURCES.ext(".class")
LOADOPENCV_JAR = File.join(JAR_DIR, "loadopencv.jar")


#The Dissemination source dir includes both DisService and DSPro
DISSEMINATION_SOURCE_DIR = File.join(JAVA_SOURCES_DIR, "dissemination")
DISSEMINATION_SOURCES = Rake::FileList[File.join(DISSEMINATION_SOURCE_DIR, "**", "*.java")]
DISSEMINATION_CLASSES = DISSEMINATION_SOURCES.ext(".class")
DISSEMINATION_JAR = File.join(JAR_DIR, "spf.jar")

UTILS_SOURCE_DIR = File.join(JAVA_SOURCES_DIR, "utils")
UTILS_SOURCES = Rake::FileList[File.join(UTILS_SOURCE_DIR, "*.java")]
UTILS_CLASSES = UTILS_SOURCES.ext(".class")
UTILS_JAR = File.join(JAR_DIR, "utils.jar")

SPF_SOURCE_DIR = File.join(JAVA_SOURCES_DIR, "spf")
SPF_SOURCES = Rake::FileList[File.join(SPF_SOURCE_DIR, "**", "*.java")]
SPF_CLASSES = SPF_SOURCES.ext(".class")
SPF_JAR = File.join(JAR_DIR, "dissemination.jar")

CLEAN.include(DISSEMINATION_CLASSES, SPF_CLASSES, UTILS_CLASSES)

CLOBBER.include(Rake::FileList.new(DISSEMINATION_JAR, SPF_JAR, UTILS_JAR))

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
  # this procedure is not correct at all
  # but commenting it it is just fine for now
  removed = 0
  #Dir.foreach(JAR_DIR) do |f|
  #  # Ignore directories (there shouldn't be any, but you never know...)
  #  next if File.directory? File.join(JAR_DIR, f)

    # f is in processed_dependencies, keep it!
  #  next if processed_dependencies.include? f

    # If we arrived here, f is an obsolete file that needs to be removed
  #  FileUtils.rm(File.join(JAR_DIR, f))
  #  puts 'Removing obsolete archives from jars directory.' if removed == 0
  #  removed += 1
  ##end
end

desc 'Compiling loadopencv pacakge for SPF Java code'
file "#{JAR_DIR}/loadopencv.jar" => LOADOPENCV_SOURCES do
  orig_dir = Dir.pwd
  Dir.chdir(LOADOPENCV_SOURCE_DIR)
  sh "javac -cp '#{JAR_DIR}/*' #{Dir[File.join('**', '*.java')].join(' ')}"
  sh "jar cvf loadopencv.jar #{Dir[File.join('**', '*.class')].each {|c| c.gsub!('$', '\$')}.join(' ')}"
  Dir.chdir(orig_dir)
  FileUtils.mv(File.join(LOADOPENCV_SOURCE_DIR, "loadopencv.jar"), JAR_DIR)
end

desc 'Compile and create archive for SPF Java code'
file "#{JAR_DIR}/spf.jar" => SPF_SOURCES do
  orig_dir = Dir.pwd
  Dir.chdir(SPF_SOURCE_DIR)
  sh "javac -cp '#{JAR_DIR}/*:#{OPENCV_JAR_LOCATION}' #{Dir[File.join('**', '*.java')].join(' ')}"
  sh "jar cvf spf.jar #{Dir[File.join('**', '*.class')].each {|c| c.gsub!('$', '\$')}.join(' ')}"
  Dir.chdir(orig_dir)
  FileUtils.mv(File.join(SPF_SOURCE_DIR, "spf.jar"), JAR_DIR)
end

desc 'Compile and create archive for Utils Java code'
file "#{JAR_DIR}/utils.jar" => UTILS_SOURCES do
  orig_dir = Dir.pwd
  Dir.chdir(JAVA_SOURCES_DIR)
  sh "javac -cp '#{JAR_DIR}/*' #{Dir[File.join('utils', '*.java')].join(' ')}"
  sh "jar cvf utils.jar #{Dir[File.join('utils', '*.class')].each {|c| c.gsub!('$', '\$')}.join(' ')}"
  Dir.chdir(orig_dir)
  FileUtils.mv(File.join(JAVA_SOURCES_DIR, "utils.jar"), JAR_DIR)
end

desc 'Compile and create archive for Disservice Java code'
file "#{JAR_DIR}/dissemination.jar" => DISSEMINATION_SOURCES do
  orig_dir = Dir.pwd
  Dir.chdir(DISSEMINATION_SOURCE_DIR)
  # sh "javac -Xlint:unchecked -cp '#{JAR_DIR}/*' #{Dir['us/**/*.java'].join(' ')}"
  sh "javac -Xlint:unchecked -cp '#{JAR_DIR}/*' #{Dir[File.join('**', '*.java')].join(' ')}"
  # sh "jar cvf disservice.jar #{Dir['us/**/*.class'].join(' ')}"
  sh "jar cvf dissemination.jar #{Dir[File.join('**', '*.class')].each {|c| c.gsub!('$', '\$')}.join(' ')}"
  Dir.chdir(orig_dir)
  FileUtils.mv(File.join(DISSEMINATION_SOURCE_DIR, "dissemination.jar"), JAR_DIR)
end

# task :all_jars => [ :get_jars, :prepare_opencv, "#{JAR_DIR}/spf.jar", "#{JAR_DIR}/disservice.jar" ] do
task :all_jars => [ :get_jars, "#{JAR_DIR}/spf.jar", "#{JAR_DIR}/utils.jar", "#{JAR_DIR}/dissemination.jar" ] do
end

task :dissemination_jar => [ "#{JAR_DIR}/dissemination.jar" ] do
end

task :spf_jar => [ "#{JAR_DIR}/spf.jar" ] do
end

task :utils_jar => [ "#{JAR_DIR}/utils.jar" ] do
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

  t.test_files = FileList[File.join('spec', '**', '*_spec.rb')]
  t.verbose = true
end

Rake::TestTask.new(:bench) do |t|
  t.libs = SPF_RUBY_SOURCE_PATHS

  t.test_files = FileList[File.join('spec', 'performance', '**', '*_benchmark.rb')]
  t.verbose = true
end

task :default => :test
