require 'java'
require 'concurrent'

java_import 'it.unife.spf.ImageDiff'
java_import 'it.unife.spf.TextRecognition'

puts "\n"
puts "+++++++++++++++++++++++++++++++++"
puts "+++++                       +++++"
puts "+++++         PIG           +++++"
puts "++++ Programmable Iot Gateway +++"
puts "+++++                       +++++"
puts "+++++                       +++++"
puts "+++++++++++++++++++++++++++++++++"
puts "\n"

puts "\nSPF::Gateway:: started!\n"

ImageDiff.calculateDiff("img-water.jpg","img-water-new.jpg",4)

#TODO : START PIG
# pig = Thread.new {SPF::Pig.new(params).run}
