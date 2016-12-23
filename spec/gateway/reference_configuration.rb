require 'spf/gateway/configuration'
require 'spf/gateway/service_manager'
require 'spf/common/extensions/fixnum'

APPLICATION_CHARACTERIZATION = <<END
application "participants",
{
  priority: 50.0,
  allow_services: [ :find_text, :audio_info ],
  service_policies: {
    find_text: {
      processing_pipeline: :ocr,
      filtering_threshold: 0.05,
      uninstall_after: 2.minutes,
      distance_decay: {
        type: :exponential,
        max: 1.km
      }
    },
    audio_info: {
      processing_pipeline: :identify_song,
      time_decay: {
        type: :linear,
        max: 2.minutes
      }
    }
  },
  dissemination_policy: {
    subscription: "participants",
    retries: 1,
    wait: 30.seconds,
    on_update: :overwrite,
    allow_channels: :WiFi
  }
}
END

REPROGRAM_CHARACTERIZATION = <<END
modify_application "participants",
  add_services: {
    a_new_service_name: {
    }
    another_new_service_name: {
    }
  },
  update_service_configurations: {
    audio_info: {
      time_decay: {
        max: 1.minute
      }
    }
  }
END

LOCATION_CHARACTERIZATION = <<END
location \
  gps_lat: "44.5432523",
  gps_lon: "13.234532"
END

PIG_REPROGRAM_REQUEST_EXAMPLE_1 = <<END
REPROGRAM #{APPLICATION_CHARACTERIZATION.bytesize}
#{APPLICATION_CHARACTERIZATION}
END

PIG_REPROGRAM_REQUEST_EXAMPLE_2 = <<END
REPROGRAM #{REPROGRAM_CHARACTERIZATION.bytesize}
#{REPROGRAM_CHARACTERIZATION}
END

PIG_SERVICE_REQUEST_EXAMPLE = <<END
REQUEST participants/find
User 3;44.838124,11.619786;find "water"
User 5;44.838124,11.619786;find "booze"
User 6;44.838124,11.619786;find "smoke"
END

# this is the whole reference configuration
# (useful for spec'ing configuration.rb)
REFERENCE_CONFIGURATION =
  APPLICATION_CHARACTERIZATION +
  LOCATION_CHARACTERIZATION

# evaluator = Object.new
# evaluator.extend SPF::Gateway::Configurable
# evaluator.instance_eval(REFERENCE_CONFIGURATION)

# # these are preprocessed portions of the reference configuration
# # (useful for spec'ing everything else)
# APPLICATION = evaluator.application


def with_gateway_reference_config(opts={})
  begin
    # create temporary file with reference configuration
    tf = Tempfile.open('REFERENCE_CONFIGURATION')
    tf.write(REFERENCE_CONFIGURATION)
    tf.close

    # create a configuration object from the reference configuration file
    service_manager = SPF::Gateway::ServiceManager.new
    disservice_handler = SPF::Gateway::DisServiceHandler.new
    conf = SPF::Gateway::PIGConfiguration.load_from_file(tf.path, service_manager, disservice_handler)

    # # apply any change from the opts parameter and validate the modified configuration
    # opts.each do |k,v|
    #   conf.send(k, v)
    # end

    conf.validate

    # pass the configuration object to the block
    yield conf
  ensure
    # delete temporary file
    tf.delete
  end
end
