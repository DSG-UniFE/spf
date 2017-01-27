module SPF
  module Gateway

    #Simple module for degree-radians conversion
    module Float
      def to_rad
        self / 180.0 * Math::PI
      end
    end

    # CLASS GPS

    # Cento = {   latitude: 44.8332215, longitude: 11.5992085 }
    # Ferrara = { latitude: 48.133333, longitude: 11.566667 }
    # d = SPF::Gateway::GPS.new(Cento,Ferrara)
    # d.distance()
    # => 27.1 (in Km)

    class GPS
      attr_reader :lat1, :lon1, :lat2, :lon2 #, :from, :to
      RADIUS = 6371

      # from = { latitude: 100, longitude: 20 }
      # to = { latitude: 100, longitude: 20 }
      def initialize(from, to)
        # @from = from
        # @to   = to
        @lat1 = from[:latitude].to_f.to_rad
        @lat2 = to[:latitude].to_f.to_rad
        @lon1 = from[:longitude].to_f.to_rad
        @lon2 = to[:longitude].to_f.to_rad
      end

      def distance(type = 'haversine')
        begin
          self.send(type.to_sym)
        rescue
          raise NotImplementedError, '#{self.class.name}: The type you have requested is not implemented, 
                                      try "cosines" or "approximation", or without params for "haversine"'
        end
      end
    end

    
    private

      def haversine
        d_lat = @lat1 - @lat2
          # (@from[:latitude] -  @to[:latitude]).to_rad
        d_lon = @lon1 - @lon2
          # (@from[:longitude] - @to[:longitude]).to_rad
        a = Math::sin(d_lat / 2) * Math::sin(d_lat / 2) +
            Math::sin(d_lon / 2) * Math::sin(d_lon / 2) *
            Math::cos(lat1) * Math::cos(lat2)
        c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))
        # p RADIUS * c
        RADIUS * c
      end

  end
end
