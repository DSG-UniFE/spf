require 'spec/spec_helper'

require 'spf/controller/configuration'

require_relative './reference_configuration'


describe SPF::Controller::Configuration do

  it 'should correctly detect number of pigs' do
    with_controller_reference_config do |conf|
      conf.size.must_equal 2
    end
  end

  it 'should correctly detect pig port' do
    with_controller_reference_config do |conf|
      conf.each do |pig|
        pig[:port].must_equal 52160
      end
    end
  end
end
