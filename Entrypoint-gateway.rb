require 'java'
require 'concurrent'
require 'results.rb'

java_import 'it.unife.spf.ImageDiff'
java_import 'it.unife.spf.TextRecognition'
# java_import 'it.unife.spf.TextRecognitionOpenOCR'
# java_import 'it.unife.spf.Count_Processing'
# java_import 'it.unife.spf.FaceRecognition'

puts "\n"
puts "+++++++++++++++++++++++++++++++++"
puts "+++++                       +++++"
puts "+++++         PIG           +++++"
puts "++++ Programmable Iot Gateway +++"
puts "+++++                       +++++"
puts "+++++                       +++++"
puts "+++++++++++++++++++++++++++++++++"
puts "\n"

puts "\nPIG:: start..\n"
puts "Current dir : "+Dir.pwd

# TextRecognitionOpenOCR.doOCR() -- OK
# puts OCR_Processing.performOCR("img-water")
# puts "Counted faces :" + FaceRecognition.doFaceRec("original.jpg") --OK
# puts "Counted cars :" + Count_Processing.CountObject("img1.jpg") --OK

#TODO : START PIG
# pig = Thread.new {SPF::Pig.new(params).run}
