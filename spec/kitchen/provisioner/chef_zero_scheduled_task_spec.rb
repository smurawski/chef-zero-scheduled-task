require_relative "../../spec_helper"

require 'pry'
require "kitchen"
require "kitchen/provisioner/chef_zero_scheduled_task"

describe Kitchen::Provisioner::ChefZeroScheduledTask do

  let(:logged_output)   { StringIO.new }
  let(:logger)          { Logger.new(logged_output) }
  let(:platform)        { stub(:os_type => "windows",
                               :shell_type => "powershell") }
  let(:suite)           { stub(:name => "fries") }
  let(:transport)       { { :username => "Administrator",
                            :password => "P@ssw0rd" } }

  let(:config) do
    { :test_base_path => "/b", :kitchen_root => "/r", :log_level => :info }
  end

  let(:instance) do
    stub(
      :name => "coolbeans",
      :logger => logger,
      :suite => suite,
      :platform => platform,
      :transport => transport,
      :diagnose => { :state_file => {:hostname => "Blah"} }
    )
  end


  let(:provisioner) do
    Kitchen::Provisioner::ChefZeroScheduledTask.new(config).finalize_config!(instance)
  end

  it "provisioner api_version is 2" do
    provisioner.diagnose_plugin[:api_version].must_equal 2
  end

  it "plugin_version is set to Kitchen::VERSION" do
    provisioner.diagnose_plugin[:version].must_equal Kitchen::VERSION
  end

  describe 'when username is not provided by the driver or task_username' do

    it 'is resolved from the transport' do
      provisioner.resolve_username.must_match "Administrator"
    end

  end
  describe 'when password is not provided by the driver or task_password' do
#    before { transport
    it 'is resolved from the transport' do 
     provisioner.resolve_password.must_match "P@ssw0rd"
    end 
  end 
end
