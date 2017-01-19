require 'java'

java_import 'util.KdTree'

module SPF
  module Controller
    class PigDS < JavaUtilities.get_proxy_class('util.KdTree$XYZPoint')
      
      attr_accessor(:alias_name, :ip, :port, :socket, :gps_lat, :gps_lon)
      
      def initialize (alias_name, ip, port, socket, gps_lat, gps_lon)
        super(gps_lon, gps_lat)
        
        @alias_name = alias_name
        @ip = ip
        @port = port
        @socket = socket
        @gps_lat = gps_lat
        @gps_lon = gps_lon
      end
      
      def to_s
        "#{@alias_name}, #{@ip}:#{@port}, [#{@gps_lat},#{@gps_lon}]"
      end
      
    end
  end
end