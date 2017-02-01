module SPF
  module Gateway

    #Simple monkey patch that adds degree-radians conversion to the Float class
    class ::Float
      def to_rad
        self / 180.0 * Math::PI
      end
    end

    
    class GPS
      
      RADIUS = 6371
      
      attr_reader :lat1, :lon1, :lat2, :lon2

      
      def initialize(from, to)
        @lat1 = from[:lat].to_f.to_rad
        @lat2 = to[:lat].to_f.to_rad
        @lon1 = from[:lon].to_f.to_rad
        @lon2 = to[:lon].to_f.to_rad
      end

      # Returns the distance in KMs
      def distance(type = 'haversine')
        begin
          self.send(type.to_sym)
        rescue
          raise NotImplementedError, "#{self.class.name}: The type you have requested is not implemented, 
                                      try 'cosines' or 'approximation', or without params for 'haversine'"
        end
      end
      
    
      private

        def haversine
          d_lat = @lat1 - @lat2
          d_lon = @lon1 - @lon2
          a = Math::sin(d_lat / 2) * Math::sin(d_lat / 2) +
              Math::sin(d_lon / 2) * Math::sin(d_lon / 2) *
              Math::cos(lat1) * Math::cos(lat2)
          c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))
          RADIUS * c
        end

    end
  end
end
