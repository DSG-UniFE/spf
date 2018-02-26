require 'resolv'
require 'uri'


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
        return false if ip.nil?
        (ip.downcase.eql? "localhost") or (ip =~ Regexp.union([Resolv::IPv4::Regex, Resolv::IPv6::Regex]) ? true : false)
      end

      def self.port?(port)
        return false if port.nil?
        (port.is_a? Numeric and (1..65535).include? port) ? true : false
      end

      def self.latitude?(lat)
        return false if lat.nil?
        regex = /^-?([1-8]?\d(?:\.\d{1,})?|90(?:\.0{1,6})?)$/
        regex =~ lat ? true : false
      end

      def self.longitude?(lon)
        return false if lon.nil?
        regex = /^-?((?:1[0-7]|[1-9])?\d(?:\.\d{1,})?|180(?:\.0{1,})?)$/
        regex =~ lon ? true : false
      end

      def self.url?(url)
        return false if url.nil?
        url =~ /\A#{URI::regexp(['http', 'https'])}\z/ ? true : false
      end

      def self.pig?(pig)
        return false if pig.nil?
        Validate.ip? pig[:ip] and Validate.port? pig[:port] and
          Validate.latitude? pig[:lat] and Validate.longitude? pig[:lon]
      end

      def self.gps_coordinates?(gps)
        Validate.latitude? gps[:lat] and Validate.longitude? gps[:lon]
      end

      def self.camera_config?(camera)
        return false unless camera[:name].length > 0
        return false unless camera[:cam_id].length > 0
        return false unless camera[:url].length > 0
        return false unless camera[:duration] >= 0
        if camera.has_key? :source
          return false unless Validate.latitude? camera[:source][:lat]
          return false unless Validate.longitude? camera[:source][:lon]
        else
          return false
        end

        return true
      end

      def self.pig_config?(alias_name, location, ip, port, tau_test, min_thread_size,
                            max_thread_size, max_queue_thread_size, queue_size)
        return false unless alias_name.length > 0
        return false unless Validate.latitude? location[:lat]
        return false unless Validate.longitude? location[:lon]
        return false unless Validate.ip? ip
        return false unless Validate.port? port
        return false unless tau_test.is_a? Numeric
        return false unless min_thread_size > 0
        return false unless max_thread_size > 0
        return false unless max_queue_thread_size >= 0
        return false unless queue_size > 0

        return true
      end

      def self.dissemination_config?(dissemination_type, ip, port)
        return false unless dissemination_type.is_a? String
        return false unless dissemination_type == "DisService" || dissemination_type == "DSPro"
        return false unless Validate.ip? ip
        return false unless Validate.port? port
        
        return true
      end

      def self.app_config?(app_name, opt)
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
              opt[key][service].each do | service_name, value |
                case service_name

                when :processing_pipelines
                  opt[key][service][service_name].each do | pipeline |
                    return false unless process.include?(pipeline.to_s + "_processing_strategy.rb")
                  end

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
