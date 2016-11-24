module SPF
  class PIGDetails

    DEFAULT_PIG_PORT = 52160
    
    attr_reader :ip
    attr_reader :port
    attr_reader :gps_latitude
    attr_reader :gps_longitude
    
    def initialize (ip, gps_latitude, gps_longitude, port = DEFAULT_PIG_PORT)
      
    end
    
  end
end