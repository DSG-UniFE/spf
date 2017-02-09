require 'java'

java_import 'utils.KdTree'


module SPF
  module Controller
    class PigDS < JavaUtilities.get_proxy_class('utils.KdTree$XYZPoint')

      attr_accessor :alias_name, :ip, :port, :socket, :lat, :lon, :applications, :updated

      def initialize (alias_name, ip, port, socket, lat, lon, applications=Hash.new)
        lat = lat.to_f
        lon = lon.to_f
        super(lon, lat)

        @alias_name = alias_name.to_sym
        @ip = ip
        @port = port
        @socket = socket
        @lat = lat
        @lon = lon
        @applications = applications
        @updated = true
      end

      def to_s
        "#{@alias_name}, #{@ip}:#{@port}, [#{@lat},#{@lon}]"
      end

    end
  end
end
