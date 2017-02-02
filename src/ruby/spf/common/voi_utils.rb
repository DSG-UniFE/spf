module SPF
  module Common
    module VoiUtils
      
      def self.calculate_max_voi(io_quality, app_priority, norm_reqs, rds_time, prox_d)

          #puts io_quality,app_priority,norm_reqs,rds_time,prox_d
          voi = io_quality * app_priority * norm_reqs * rds_time * prox_d
          puts "VoI: #{voi}"
          return voi
      end

      def self.most_recent_time(times_array)
          #time of the first request in the array
          time = times_array[0]
          times_array.each do |t|
            time = t if t > time
          end

          return time
      end

      def self.closest_requestor_location(locations_array, ref_position)

          #ref_position => Sensor location if available, else Pig.location
          min_distance = SPF::Gateway::GPS.new(ref_position, locations_array[0]).distance
          min_location = locations_array[0]
          locations_array.each do |l|
            new_distance = SPF::Gateway::GPS.new(ref_position, l).distance
            min_distance = new_distance and min_location = l if new_distance < min_distance
          end
          return min_location
      end
    end
  end
end
