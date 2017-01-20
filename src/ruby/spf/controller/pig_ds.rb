require 'java'

java_import 'utils.KdTree'

module SPF
  module Controller
    class PigDS < JavaUtilities.get_proxy_class('utils.KdTree$XYZPoint')

      attr_accessor(:alias_name, :ip, :port, :socket, :gps_lat, :gps_lon, :applications)

      def initialize (alias_name, ip, port, socket, gps_lat, gps_lon, applications=Hash.new)
        gps_lat = gps_lat.to_f
        gps_lon = gps_lon.to_f
        super(gps_lon, gps_lat)

        @alias_name = alias_name.to_sym
        @ip = ip
        @port = port
        @socket = socket
        @gps_lat = gps_lat
        @gps_lon = gps_lon
        @applications = applications
      end

      def to_s
        "#{@alias_name}, #{@ip}:#{@port}, [#{@gps_lat},#{@gps_lon}]"
      end

    end
  end
end
