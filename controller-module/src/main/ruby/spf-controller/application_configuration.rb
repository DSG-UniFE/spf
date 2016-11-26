require 'spf-common/logger'

module SPF
  module Controller

    class ApplicationConfiguration
      include SPF::Logging

      APP_FOLDER = "controller-module/app_configurations/*"

      attr_reader :conf

      private

        def initialize
          @conf = {}
        end

        def validate(opt)
          # check conf
          # application "participants", {
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


        end

      def application(name, opt)
        if validate(opt)
          @conf[name.to_sym] ||= opt
        else
          logger.warn("Configuration \"#{name}\" is not valid")
        end
      end

      public

        def self.load_from_file

          # create configuration object
          conf = Configuration.new

          configurations = Dir[APP_FOLDER]

          configurations.each do |conf_name|

            # take the file content and pass it to instance_eval
            conf.instance_eval(File.new(conf_name, 'r').read)
          end

          # return new object
          conf
        end

    end

  end
end
