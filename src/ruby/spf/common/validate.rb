require 'resolv'

module SPF
  module Common
    class Validate

      @@KEYS = [:priority, :allow_services, :service_policies, :dissemination_policy]
      @@DISTANCE_TYPES = [:linear, :exponential]
      @@CHANNELS = [:WiFi, :cellular]
      @@SERVICES_FOLDER = File.join('src', 'ruby', 'spf', 'gateway', 'service-strategies')
      @@PROCESS_FOLDER = File.join('src', 'ruby', 'spf', 'gateway', 'processing-strategies')

      def self.ip?(ip)
        ip =~ Regexp.union([Resolv::IPv4::Regex, Resolv::IPv6::Regex]) ? true : false
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
        (Validate.ip? pig[:ip] and Validate.port? pig[:port] and \
          Validate.latitude? pig[:lat] and \
          Validate.latitude? pig[:lat]) ? true : false
      end

      def self.conf?(opt)
        return false unless (opt.keys & @@KEYS).any?

        services = Dir.entries(@@SERVICES_FOLDER)
        process = Dir.entries(@@PROCESS_FOLDER)

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
              case service

              when :find_text
                return false unless process.include?(opt[key][service][:processing_pipeline].to_s + "_processing_strategy.rb")

                return false unless opt[key][service][:filtering_threshold].between?(0, 1)

                return false unless opt[key][service][:uninstall_after] >= 0

                return false unless @@DISTANCE_TYPES.include?(opt[key][service][:distance_decay][:type])
                return false unless opt[key][service][:distance_decay][:max] >= 0

              when :audio_info

                # return false unless process.include?(opt[key][service][:processing_pipeline].to_s + "_processing_strategy.rb")

                return false unless @@DISTANCE_TYPES.include?(opt[key][service][:time_decay][:type])
                return false unless opt[key][service][:time_decay][:max] >= 0
              else
                return false
              end

            end

          when :dissemination_policy
            return false unless opt[key][:subscription].is_a? String
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
      end

    end
  end
end
