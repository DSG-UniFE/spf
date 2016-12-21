require 'resolv'

module SPF
  module Common
    class Validate
      KEYS = ["priority".to_sym,
        "allow_services".to_sym,
        "service_policies".to_sym,
        "dissemination_policy".to_sym]
      SERVICES_FOLDER = File.join('src', 'ruby', 'gateway', 'service-strategies')
      PROCESS_FOLDER = File.join('src', 'ruby', 'gateway', 'processing-strategies')
      TIMES = ["second", "seconds", "minute", "minutes", "hour", "hours", "day",
        "days", "month", "months", "year", "years"]
      TYPES_OF_DISTANCE = ["linear", "exponential"]
      CHANNELS = ["WiFi", "cellular"]

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
        # check conf
        # {
        #   priority: 50.0, -> 0..100
        #   allow_services: [ :find_text, :listen ], # controllare 'service-strategies'
        #   service_policies: {
        #     find_text: {
        #       processing_pipeline: :ocr, -> 'processing-strategies'
        #       filtering_threshold: 0.05, -> 0..1
        #       uninstall_after: 2.minutes, -> >0
        #       distance_decay: {
        #         type: :exponential, -> linear or exp
        #         max: 1.km -> >0
        #       }
        #     },
        #     listen: {
        #       processing_pipeline: :identify_song,
        #       time_decay: {
        #         type: :linear,
        #         max: 2.minutes
        #       }
        #     }
        #   },
        #   dissemination_policy: {
        #     subscription: "participants", -> stringa
        #     retries: 1, -> =>0
        #     wait: 30.seconds, -> =>0
        #     on_update: :overwrite, -> ?
        #     allow_channels: :WiFi -> wifi cellular
        #   }
        # }

        return false unless (opt.keys & KEYS).any? and (opt.length == KEYS.length)

        opt.keys.each do |key|

          case key

          when "priority".to_sym
            return false unless opt[key].between?(0, 100)

          when "allow_services".to_sym
            services = Dir.glob(File.join(SERVICES_FOLDER, "*")
            opt[:allow_services].each do |service|
              return false unless services.include?(service.to_s + "_service_strategy.rb")
            end

          when  "service_policies".to_sym
            opt[key][:service_policies].keys.each do | service |
              case service
              when "find_text".to_sym
                process = Dir.glob(File.join(PROCESS_FOLDER, "*")
                opt[key][:service_policies][:processing_pipeline].each do |pro|
                  return false unless process.include?(pro.to_s + "_processing_strategy.rb")
                end

                return false unless opt[key][:service_policies][:processing_pipeline][:filtering_threshold].between?(0, 1)

                uninstall_after = opt[key][:service_policies][:processing_pipeline][:uninstall_after]

                n_time, s_time = uninstall_after.split('.')
                return false unless n_time >= 0
                return false unless TIMES.include?(s_time)

                return false unless TYPES_OF_DISTANCE.include?(opt[key][:service_policies][:processing_pipeline][:distance_decay][:type])
                return false unless opt[key][:service_policies][:processing_pipeline][:distance_decay][:max] >= 0

              # TODO
              # when "listen".to_sym

              else
                return false

              end

          when "dissemination_policy".to_sym
            return false unless opt[key][:dissemination_policy][:subscription].is_a? String
            return false unless opt[key][:dissemination_policy][:retries] >= 0
            return false unless opt[key][:dissemination_policy][:wait] >= 0

            # TODO
            # return false unless opt[key][:dissemination_policy][:on_update]

            return false unless CHANNELS.include?(opt[key][:dissemination_policy][:allow_channels]

          else
            return false
          end

        end

        return true

      end

    end
  end
end
