require 'java'
require 'csv' # -- ok
module Results

    @path="/pi"
      
    def Results.print_all_txt
    
    	list_txt = Dir.glob("Frames/*.txt")
    	puts "Numero files:"
    	puts list_txt.length
    	puts "\n"
    	list_txt.each{ |file|
    
    		File.open(file, "r") do |f|
    	 	 f.each_line do |line|
    	  	  puts line
    	  	end
    		end
    	}
    end
    
    def Results.process_with_steps
    
    	list = Dir.glob("Frames/*.png").sort
    
    	steps=[2,4,8,16]
    
    	steps.each 	{ |step|
    		t = Time.now
    
    		processed = 0
    		last_raw_data = list[0]
    		list.shift
    		list.each do |x| 
    			
    			last_raw_data=x and processed+=1 if ImageDiff.calculateDiff1(last_raw_data,x,step) >= threshold 
    
    		end
    		time = Time.now - t
    		puts processed.to_s+" processati con step = "+step.to_s+" in "+time.to_s+" secondi\n"
    
    	}
    
=begin
    risultati = ""
    44 processati con step = 2 in 12.949 secondi
    42 processati con step = 4 in 12.802 secondi
    45 processati con step = 8 in 12.567 secondi
    45 processati con step = 16 in 12.434 secondi
    
    quindi prendiamo step = 8
    
=end
    
    end
    
    
    
    def Results.process_with_thresholds
    	
      Results.remove_txt
      Results.remove_intermediate_images
    
    	list = Dir.glob("/home"+@path+"/Frames/*.png").sort
    	thresholds = 0.0.step(0.4,0.05)
    	st = 8
    	CSV.open("/home"+@path+"/OCR-pi-thresholds-"+Time.now.to_s+".csv", "wb") do |csv|
      csv << ["Processed", "threshold","Time"]
    	puts "Creato file csv.\n"
    	
    	thresholds.each {|th|
    	  puts "Processo con soglia "+th.to_s
    		t = Time.now
    		processed = 0
    		last_raw_data = list[0]
    		list.shift
    		list.each do |x| 
          if ImageDiff.calculateDiff1(last_raw_data,x,st) >= th
                last_raw_data=x
                processed+=1
                OCR_Processing.performOCR(x) 
                puts "Processing "+processed.to_s+" : "+x.to_s+" .."
          end
    			#last_raw_data=x and processed+=1 and puts processed.to_s and OCR_Processing.performOCR(x) if ImageDiff.calculateDiff1(last_raw_data,x,st) >= th 
    
    		end
    		time = Time.now - t
    		puts "\n"+processed.to_s+" processati con threshold = "+th.to_s+" in "+time.to_s+" secondi\n"
    		csv << [processed,th,time]
    	}
    
    	end	
    		
=begin
    	Risulati su PC Host senza pero' OCR.performOCR, solamente con ImageDiff
    	161 processati con threshold = 0.0 in 12.971 secondi
    	84 processati con threshold = 0.05 in 12.748 secondi
    	45 processati con threshold = 0.1 in 12.674 secondi
    	23 processati con threshold = 0.15000000000000002 in 12.338 secondi
    	16 processati con threshold = 0.2 in 12.613 secondi
    	9 processati con threshold = 0.25 in 12.529 secondi
    	9 processati con threshold = 0.30000000000000004 in 12.437 secondi
    	3 processati con threshold = 0.35000000000000003 in 12.366 secondi
    	2 processati con threshold = 0.4 in 12.191 secondi
    	0 processati con threshold = 0.45 in 12.361 secondi
    	0 processati con threshold = 0.5 in 11.673 secondi
    
=end
    
    end
    
    def Results.createCSV
      CSV.open("/home"+@path+"/Desktop/processing-"+Time.now.to_s+".csv", "wb") do |csv|
      csv << ["Processed", "threshold","Time"]
      csv << [1,2,3]
      end
    end
    
    
    def Results.remove_txt
    	list_txt = Dir.glob("Frames/*.txt")
    	list_txt.each { |x|
    
    		File.delete(x)
    				
    	}
    end
    
    def Results.remove_intermediate_images
    	list_jpg = Dir.glob("Frames/*.jpg")
    	list_jpg.each { |x|
    
    		File.delete(x)
    				
    	}
    	
    end
    
    def Results.processOCR(threshold)
      
    	puts "Removing old txt's and intermediate images.."
      Results.remove_txt
      Results.remove_intermediate_images
    	puts "All removed.\n"
    
    	list = Dir.glob("/home"+@path+"/Frames/*.png").sort
    	st = 8
    	processed = 0
    	last_raw_data = list[0]
    	list.shift
    	CSV.open("/home"+@path+"/OCR-processing-"+Time.now.to_s+".csv", "wb") do |csv|
      csv << ["Processed", "threshold","Time"]
      t = Time.now
    	list.each do |x| 
    		#Prendo come soglia 0.2, in modo che vengano processate 16 immagini
    		
    		if ImageDiff.calculateDiff1(last_raw_data,x,st) >= threshold
    			last_raw_data=x
    			processed+=1
    			OCR_Processing.performOCR(x) 
    			#puts "Processed :"+x.to_s+"in "+time.to_s+" secondi"
    			end
    	end
    	time = Time.now - t
    	puts processed.to_s + threshold.to_s + time.to_s
    	csv << [processed,threshold,time]
    	end
    Results.print_all_txt
    end
end
