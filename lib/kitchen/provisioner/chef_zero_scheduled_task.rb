# -*- encoding: utf-8 -*-
#
# Author:: Steven Murawski (<smurawski@chef.io>)
#
# Copyright (C) 2015, Chef Software
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "kitchen/provisioner/chef_zero"

module Kitchen
  module Provisioner
    # Chef Zero provisioner to run in scheduled task on Windows
    class ChefZeroScheduledTask < ChefZero
      kitchen_provisioner_api_version 2

      plugin_version Kitchen::VERSION

      default_config :task_username

      default_config :task_password

      def init_command
        if windows_os?
          info("Creating the scheduled task.")
          wrap_shell_code("#{super}\n#{setup_scheduled_task_command}")
        else
          super
        end
      end

      def run_command
        if windows_os?
          script = "$script = @'\n#{scheduled_task_command_script}\n'@\n" \
          "\n$ExecutionContext.InvokeCommand.ExpandString($Script) | out-file \"$env:temp/kitchen/chef-client-script.ps1\"" \
          "\n#{run_scheduled_task_command}"
          wrap_shell_code(script)
        else
          super
        end
      end

      # private

      def local_state_file
        @local_state_file ||= @instance.diagnose[:state_file]
      end

      def task_username
        if config[:task_username]
          config[:task_username]
        else
          if local_state_file.key?(:username)
            local_state_file[:username]
          else
            @instance.transport[:username]
          end
        end
      end

      def task_password
        unless config[:task_password]
          if local_state_file.key?(:password)
            local_state_file[:password]
          else
            @instance.transport[:password]
          end
        end
      end

      def run_scheduled_task_command
        <<-EOH
try {
  Add-Type -AssemblyName System.Core
  $npipeServer = new-object System.IO.Pipes.NamedPipeServerStream('task', 
    [System.IO.Pipes.PipeDirection]::In)
  $pipeReader = new-object System.IO.StreamReader($npipeServer)
  schtasks /run /tn "chef-tk" /i
  $npipeserver.waitforconnection()
  $host.ui.writeline('Connected to the scheduled task.')
  while ($npipeserver.IsConnected) {
    $output = $pipereader.ReadLine()
    if ($output -like 'SCHEDULED_TASK_DONE:*') {
      $exit_code = ($output -replace 'SCHEDULED_TASK_DONE:').trim()
    }
    else { $host.ui.WriteLine($output) } } }
finally {
  $pipereader.dispose()
  $npipeserver.dispose()
  $host.setshouldexit($exit_code)
}
        EOH
      end

      def new_scheduled_task_command
        "schtasks /create /tn 'chef-tk' " \
        "/ru '#{task_username}' /rp '#{task_password}' " \
        "/sc daily /st 00:00 /rl HIGHEST /f "
      end

      def new_scheduled_task_command_line_ps
        "/tr $executioncontext.invokecommand.expandstring(" \
        '"powershell -executionpolicy unrestricted -File '
      end

      def setup_scheduled_task_command
        new_scheduled_task_command +
          new_scheduled_task_command_line_ps +
          remote_chef_client_script +
          '")'
      end

      def remote_chef_client_script
        @remote_script_path ||= remote_path_join(
          config[:root_path], "chef-client-script.ps1")
      end

      def scheduled_task_command_script
        <<-EOH
Add-Type -AssemblyName System.Core
start-sleep -seconds 5;
`$npipeClient = new-object System.IO.Pipes.NamedPipeClientStream(`$env:ComputerName,
  `'task`', [System.IO.Pipes.PipeDirection]::Out);
`$npipeclient.connect();
`$pipeWriter = new-object System.IO.StreamWriter(`$npipeClient);
`$pipeWriter.AutoFlush = `$true;
#{client_zero_command} |
  foreach-object {} {`$pipewriter.writeline(`$_)} {
    `$pipewriter.writeline("SCHEDULED_TASK_DONE: `$LastExitCode");
    `$pipewriter.dispose();
    `$npipeclient.dispose()
  }
EOH
      end

      def prepare_client_zero_script
        File.open(File.join(sandbox_path, "chef-client-script.ps1"), "w") do |file|
          file.write(Util.outdent!(scheduled_task_command_script))
        end
      end

      def client_zero_command
        [local_mode_command, *chef_client_args].join(" ")
      end

      def chef_client_args
        level = config[:log_level] == :info ? :info : config[:log_level]
        args = [
          "--config #{remote_path_join(config[:root_path], "client.rb")}",
          "--log_level #{level}",
          "--force-formatter",
          "--no-color"
        ]
        add_optional_chef_client_args!(args)

        args
      end
    end
  end
end
