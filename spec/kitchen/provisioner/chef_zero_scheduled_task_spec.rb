require_relative "../../spec_helper"

require "pry"
require "kitchen"
require "kitchen/provisioner/chef_zero_scheduled_task"

describe Kitchen::Provisioner::ChefZeroScheduledTask do

  let(:logged_output) { StringIO.new }
  let(:logger) { Logger.new(logged_output) }
  let(:platform) do
    stub(:os_type => "windows", :shell_type => "powershell")
  end
  let(:suite) { stub(:name => "fries") }
  let(:transport) do
    { :username => "Administrator", :password => "P@ssw0rd" }
  end
  let(:diagnose) { { :state_file => { :hostname => "Blah" } } }

  let(:config) do
    { :test_base_path => "/b",
      :kitchen_root => "/r",
      :log_level => :info,
      :root_path => "c:\\" }
  end

  let(:instance) do
    stub(
      :name => "coolbeans",
      :logger => logger,
      :suite => suite,
      :platform => platform,
      :transport => transport,
      :diagnose => diagnose
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

  describe "when username is not provided by the driver or task_username" do
    it "is resolved from the transport" do
      provisioner.task_username.must_match "Administrator"
    end
  end

  describe "when password is not provided by the driver or task_password" do
    it "is resolved from the transport" do
      provisioner.task_password.must_match "P@ssw0rd"
    end
  end

  describe "new_scheduled_task_command" do
    it "returns a valid command line" do
      provisioner.
        new_scheduled_task_command.
        must_match("schtasks /create /tn 'chef-tk' /ru " \
        "'Administrator' /rp 'P@ssw0rd' /sc daily /st 00:00 /f ")
    end
  end

  describe "new_scheduled_task_command_line_ps" do
    it "returns a valid task to execute" do
      provisioner.
        new_scheduled_task_command_line_ps.
        must_match("/tr $executioncontext.invokecommand.expandstring(" \
        '"powershell -executionpolicy unrestricted -File ')
    end
  end

  describe "remote_chef_client_script" do
    it "returns a valid path to the script to execute" do
      provisioner.
        remote_chef_client_script.
        must_match("c:\\chef-client-script.ps1")
    end
  end

end
