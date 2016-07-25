require 'spf/gateway/configuration'
require 'spf/extensions/fixnum'

APPLICATION_CHARACTERIZATION = <<END
application "participants",
  priority: 50.0,
  allow_services: [ :find, :listen ],
  service_policies: {
    find: {
      uninstall_after: 2.minutes,
      distance_decay: { type: :exponential,
                        max: 1.km },
      filtering_threshold: 0.05
    },
    listen: {
      require_processing: :identify_song,
      time_decay: { type: :linear,
                    max: 2.minutes }
    }
  },
  dissemination_policy: {
    subscription: "participants",
    retries: 1,
    wait: 30.seconds,
    on_update: :overwrite,
    allow_channels: :WiFi
  }
END


# this is the whole reference configuration
# (useful for spec'ing configuration.rb)
REFERENCE_CONFIGURATION =
  APPLICATION_CHARACTERIZATION

# evaluator = Object.new
# evaluator.extend SPF::Gateway::Configurable
# evaluator.instance_eval(REFERENCE_CONFIGURATION)

# # these are preprocessed portions of the reference configuration
# # (useful for spec'ing everything else)
# APPLICATION = evaluator.application


def with_reference_config(opts={})
  begin
    # create temporary file with reference configuration
    tf = Tempfile.open('REFERENCE_CONFIGURATION')
    tf.write(REFERENCE_CONFIGURATION)
    tf.close

    # create a configuration object from the reference configuration file
    conf = SPF::Gateway::Configuration.load_from_file(tf.path)

    # apply any change from the opts parameter and validate the modified configuration
    opts.each do |k,v|
      conf.send(k, v)
    end
    conf.validate

    # pass the configuration object to the block
    yield conf
  ensure
    # delete temporary file
    tf.delete
  end
end