require 'spf/common/gps'

module SPF
  module Common
    module VoiUtils
      
      # Calculate the VoI from the parameters.
      #
      # @param io_quality [Float] The quality of the IO.
      # @param app_priority [Float] The priority of the application.
      # @param norm_reqs [Float] The number of requestors interested in the IO, normalized by  
      #                          the highest number of requests received by all services.
      # @param rds_time [Float] The time decay factor.
      # @param prox_d [Float] The distance decay factor
      def calculate_voi(io_quality, app_priority, norm_reqs, rds_time, prox_d)
        voi = io_quality * app_priority * norm_reqs * rds_time * prox_d
        puts "VoI: #{voi}"

        voi
      end

      # Returns the most recent (greatest) time in the Array passed in as parameter.
      #
      # @param times_array [Array] An array of Times.
      def most_recent_time(times_array)
        times_array.max
      end

      # Returns the location of the requestor that is the closest to a reference position
      #
      # @param locations_array [Array] An array of GPS coordinates.
      # @param ref_position [Hash] An Hash that contains the GPS coordinates 
      #                            of the reference position.
      def closest_requestor_location(locations_array, ref_position)
        min_distance = Float::INFINITY
        min_location = nil
        locations_array.each do |l|
          new_distance = GPS.distance(ref_position, l)
          min_distance = new_distance and min_location = l if new_distance < min_distance
        end

        min_location
      end

      # Returns the distance of the closest requestor from a reference position
      #
      # @param locations_array [Array] An array of GPS coordinates.
      # @param ref_position [Hash] An Hash that contains the GPS coordinates 
      #                            of the reference position.
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
