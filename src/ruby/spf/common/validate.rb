require 'resolv'


module SPF
  module Common
    class Validate

      @@KEYS = [:priority, :allow_services, :service_policies, :dissemination_policy]
      @@DISTANCE_TYPES = [:linear, :exponential]
      @@CHANNELS = [:WiFi, :cellular]
      # @@SERVICES_FOLDER = File.join('src', 'ruby', 'spf', 'gateway', 'service-strategies')
      # @@PROCESS_FOLDER = File.join('src', 'ruby', 'spf', 'gateway', 'processing-strategies')
      @@SERVICES_FOLDER = File.expand_path(File.join(File.dirname(__FILE__), '..', 'gateway', 'service-strategies'))
      @@PROCESS_FOLDER = File.expand_path(File.join(File.dirname(__FILE__), '..', 'gateway', 'processing-strategies'))
      @@APPLICATION_CONFIG_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'etc', 'controller', 'app_configurations'))

      def self.ip?(ip)
        (ip.eql? "localhost") or (ip =~ Regexp.union([Resolv::IPv4::Regex, Resolv::IPv6::Regex]) ? true : false)
      end

      def self.port?(port)
        (port.is_a? Numeric and (1..65535).include? port) ? true : false
      end

      def self.latitude?(lat)
        regex = /^-?([1-8]?\d(?:\.\d{1,})?|90(?:\.0{1,6})?)$/
        regex =~ lat ? true : false
      end

      def self.longitude?(lon)
        regex = /^-?((?:1[0-7]|[1-9])?\d(?:\.\d{1,})?|180(?:\.0{1,})?)$/
        regex =~ lon ? true : false
      end

      def self.pig?(pig)
        Validate.ip? pig[:ip] and Validate.port? pig[:port] and
          Validate.latitude? pig[:gps_lat] and Validate.longitude? pig[:gps_lon]
      end

      def self.conf?(app_name, opt)
        return false unless (opt.keys & @@KEYS).any?

        services = Dir.entries(@@SERVICES_FOLDER)
        process = Dir.entries(@@PROCESS_FOLDER)
        applications = Dir.entries(@@APPLICATION_CONFIG_DIR)

        return false unless applications.include? app_name

        opt.keys.each do |key|
          case key

          when :priority
            return false unless opt[key].between?(0, 100)

          when :allow_services
            opt[key].each do |service|
              return false unless services.include?(service.to_s + "_service_strategy.rb")
            end

          when :service_policies
            opt[key].keys.each do | service |
              opt[key][service].each do | key_service, value |
                case key_service

                when :processing_pipeline
                  return false unless process.include?(value.to_s + "_processing_strategy.rb")

                when :filtering_threshold
                  return false unless value.between?(0, 1)

                when :expire_after
                  return false unless value >= 0

                when :on_demand
                  return false unless value == true or value == false
                  unless value
                     return false unless opt[key][service][:uninstall_after] >= 0
                  end
                when :uninstall_after
                  next

                when :distance_decay
                  return false unless @@DISTANCE_TYPES.include?(value[:type])
                  return false unless value[:max] >= 0

                when :time_decay
                  return false unless @@DISTANCE_TYPES.include?(value[:type])
                  return false unless value[:max] >= 0

                else
                    return false
                end
              end
            end

          when :dissemination_policy
            return false unless opt[key][:subscription].eql? app_name
            return false unless opt[key][:retries] >= 0
            return false unless opt[key][:wait] >= 0

            # TODO
            # return false unless opt[key][service][:on_update]

            return false unless @@CHANNELS.include?(opt[key][:allow_channels])

          else
            return false

          end

        end

        return true

      rescue
        return false
      end

    end
  end
end
