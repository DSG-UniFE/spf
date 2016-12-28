# $LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'minitest/spec'
require 'minitest-spec-context'

require 'minitest/autorun'

require 'minitest/reporters'
Minitest::Reporters.use!
# Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new(color: true)

if RUBY_PLATFORM =~ /java/
  opencv_jar = '/usr/share/java/opencv.jar'
  $CLASSPATH << opencv_jar unless $CLASSPATH.include?(opencv_jar)
  JARS_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', 'jars'))
  Dir["#{JARS_DIR}/*.jar"].each do |jar|
    $CLASSPATH << jar unless $CLASSPATH.include?(jar)
  end
end
