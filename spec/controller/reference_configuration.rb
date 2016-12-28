require 'spf/controller/configuration'


APPLICATION_CONFIG_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'etc', 'controller', 'app_configurations'))

PIGS_CHARACTERIZATION = <<END
add_pigs \
  [
    {
      ip: "127.0.0.1",
      port: 52160,
      gps_lat: "44.5432523",
      gps_lon: "13.234532"
    },
  ]
END


# this is the whole reference configuration
# (useful for spec'ing configuration.rb)
CONTROLLER_REFERENCE_CONFIGURATION =
  PIGS_CHARACTERIZATION

# evaluator = BasicObject.new
# evaluator.extend SPF::Controller::Configurable
# evaluator.instance_eval(REFERENCE_CONFIGURATION)

# # these are preprocessed portions of the reference configuration
# # (useful for spec'ing everything else)
# PIGS = evaluator.pigs


def with_controller_reference_config(opts={})
  begin
    # create temporary file with reference configuration
    tf = Tempfile.open('CONTROLLER_REFERENCE_CONFIGURATION')
    tf.write(CONTROLLER_REFERENCE_CONFIGURATION)
    tf.close

    # create a configuration object from the reference configuration file
    conf = SPF::Controller::Configuration.load_from_file(tf.path)

    # # apply any change from the opts parameter and validate the modified configuration
    # opts.each do |k,v|
    #   conf.send(k, v)
    # end
    # conf.validate

    # pass the configuration object to the block
    yield conf
  ensure
    # delete temporary file
    tf.delete
  end
end
