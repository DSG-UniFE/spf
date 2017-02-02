require 'spf/common/gps'

module SPF
  module Common
    module VoiUtils
      
      def calculate_max_voi(io_quality, app_priority, norm_reqs, rds_time, prox_d)
        #puts io_quality,app_priority,norm_reqs,rds_time,prox_d
        voi = io_quality * app_priority * norm_reqs * rds_time * prox_d
        puts "VoI: #{voi}"
        
        voi
      end

      def most_recent_time(times_array)
        # most recent time is the max time
        times_array.max
      end

      def closest_requestor_location(locations_array, ref_position)
        #ref_position => Sensor location if available, else Pig.location
        min_distance = GPS.new(ref_position, locations_array[0]).distance
        min_location = locations_array[0]
        locations_array.each do |l|
          new_distance = GPS.new(ref_position, l).distance
          min_distance = new_distance and min_location = l if new_distance < min_distance
        end
        
        min_location
      end
      
    end
  end
end
