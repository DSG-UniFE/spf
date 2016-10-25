module SPF
  module Gateway
    
    #Simple module for degree-radians conversion
    module Float
          def self.to_rad angle
            angle / 180 * Math::PI
          end
    end
    
    # CLASS GPS

    # Cento = {   latitude: 44.8332215, longitude: 11.5992085 } 
    # Ferrara = { latitude: 48.133333, longitude: 11.566667 }
    # d = SPF::Gateway::GPS.new(Cento,Ferrara)
    # d.distance()
    # => 27.1 (in Km)
    
    class GPS
    
        include Float
        include Math
        attr_reader :from, :to, :lat1, :lon1, :lat2, :lon2
        RADIUS = 6371
    
          def initialize(from, to)
            @from = from
            @to = to
            set_variables
          end
    
          def distance(type = 'haversine')
              begin
                self.send(type.to_sym)
              rescue
                raise NotImplementedError, 'The type you have requested is not implemented, try "cosines" or "approximation", or without params for "haversine"'
              end
          end
          
          def haversine
            d_lat = Float.to_rad(from[:latitude] - to[:latitude])
            d_lon = Float.to_rad(from[:longitude] - to[:longitude])
            a = sin(d_lat / 2) * sin(d_lat / 2) + sin(d_lon / 2) *
              sin(d_lon / 2) * cos(lat1) * cos(lat2)
            c = 2 * atan2(sqrt(a), sqrt(1-a))
            p RADIUS * c
        end
    
          def set_variables
            @lat1 = Float.to_rad from[:latitude]
            @lat2 = Float.to_rad to[:latitude]
            @lon1 = Float.to_rad from[:longitude]
            @lon2 = Float.to_rad to[:longitude]
          end
      end

  end
end
