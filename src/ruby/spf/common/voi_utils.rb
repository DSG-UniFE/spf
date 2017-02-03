require 'spf/common/gps'

module SPF
  module Common
    module VoiUtils
      
      def calculate_voi(io_quality, app_priority, norm_reqs, rds_time, prox_d)
        voi = io_quality * app_priority * norm_reqs * rds_time * prox_d
        puts "VoI: #{voi}"
        
        voi
      end

      def most_recent_time(times_array)
        # most recent time is the max time
        times_array.max
      end

      def closest_requestor_location(locations_array, ref_position)
        min_distance = Float::INFINITY
        min_location = nil
        locations_array.each do |l|
          new_distance = GPS.distance(ref_position, l)
          min_distance = new_distance and min_location = l if new_distance < min_distance
        end
        
        min_location
      end

      def distance_to_closest_requestor(locations_array, ref_position)
        min_distance = Float::INFINITY
        locations_array.each do |l|
          min_distance = [GPS.distance(ref_position, l), min_distance].min
        end
        
        min_distance
      end
      
    end
  end
end
