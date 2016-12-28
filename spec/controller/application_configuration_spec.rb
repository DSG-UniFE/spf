require 'spec/spec_helper'

require 'spf/controller/application_configuration'

require_relative './reference_configuration'


describe SPF::Controller::ApplicationConfiguration do

  it 'should correctly detect number of application configurations' do
    app_conf = {}
    Dir.foreach(APPLICATION_CONFIG_DIR) do |ac|
      config_pwd = File.join(APPLICATION_CONFIG_DIR, ac)
      next if File.directory? config_pwd
      app_conf[ac] = SPF::Controller::ApplicationConfiguration.load_from_file(config_pwd)
    end
    app_conf.size.must_equal 1
  end

  it 'should correctly detect "participants" application priority' do
    config_pwd = File.join(APPLICATION_CONFIG_DIR, "participants")
    app_conf = SPF::Controller::ApplicationConfiguration.load_from_file(config_pwd)
    app_conf[:participants][:priority].must_equal 50.0
  end

end
