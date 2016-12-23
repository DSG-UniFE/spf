require 'spec/spec_helper'

require 'spf/controller/application_configuration'

require_relative './reference_configuration'


describe SPF::Controller::ApplicationConfiguration do

  it 'should load application configurations' do
    app_conf = {}
    Dir.foreach(APPLICATION_CONFIG_DIR) do |ac|
      next if File.directory? ac
      app_conf[ac] = SPF::Controller::ApplicationConfiguration.load_from_file(ac)
    end
    app_conf.size.must_equal 1
  end

end
