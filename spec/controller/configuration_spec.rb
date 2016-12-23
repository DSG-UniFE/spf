require 'spec/spec_helper'

require 'spf/controller/configuration'

require_relative './reference_configuration'


describe SPF::Controller::Configuration do

  it 'should correctly detect number of pigs' do
    with_controller_reference_config do |conf|
      conf.pigs.size.must_equal 2
    end
  end

end
