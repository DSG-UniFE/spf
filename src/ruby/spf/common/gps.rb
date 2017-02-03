require 'spf/common/exceptions'

module SPF
  module Common

    #Simple monkey patch that adds degree-radians conversion to the Float class
    class ::Float
      def to_rad
        self / 180.0 * Math::PI
      end
    end


    class GPS
      RADIUS = 6371

      # Returns the distance in KMs between two points
      #
      # @param from [Hash] The GPS coordinates of the first point.
      # @param to [Hash] The GPS coordinates of the second point.
      # @param type [String] The name of the function to use to compute the distance.
      def self.distance(from, to, type='haversine')
        self.check_gps_coordinates(from, to)
        begin
          self.send(type.to_sym, from, to)
        rescue
          raise NotImplementedError, "#{self.class.name}: The requested distance type is not implemented"
        end
      end

      
      private

        def self.check_gps_coordinates(from, to)
          raise NilParameterException, "#{self.class.name}: nil parameter" if from.nil? || to.nil?
          raise ArgumentException, "#{self.class.name}: Parameters from: #{from} and to: #{to} \
            are not correct GPS coordinates" if !from.has_key?(:lat) || !to.has_key?(:lat) ||
                                                !from.has_key?(:lon) || !to.has_key?(:lon)
        rescue NoMethodError => e
          raise TypeError, "#{self.class.name}: At least one method parameter is not a Hash type"
        end

        def self.haversine(from, to)
          d_lat = from[:lat].to_f - to[:lat].to_f
          d_lon = from[:lon].to_f - to[:lon].to_f
          a = Math::sin(d_lat / 2) * Math::sin(d_lat / 2) +
              Math::sin(d_lon / 2) * Math::sin(d_lon / 2) *
              Math::cos(from[:lat].to_f) * Math::cos(to[:lat].to_f)

          c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))
          RADIUS * c
        rescue NoMethodError => e
          raise TypeError, "#{self.class.name}: At least one GPS coordinate is not a number"
        end

    end
  end
end
