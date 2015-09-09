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

require 'kitchen/provisioner/chef_zero'

module Kitchen
  module Provisioner
    # Chef Zero provisioner to run in scheduled task on Windows
    class ChefZeroScheduledTask < ChefZero
      kitchen_provisioner_api_version 2

      plugin_version Kitchen::VERSION

      default_config :task_username

      default_config :task_password

      def create_sandbox
        super
        return unless windows_os?
        prepare_client_zero_script
      end

      def init_command
        resolve_username_and_password
        wrap_shell_code(setup_scheduled_task_command)
      end

      # assuming a version of Chef with local mode.
      def prepare_command
        return unless windows_os?
        info('Creating a script to run chef client.')
        wrap_shell_code(scheduled_task_command)
      end

      def run_command
        wrap_shell_code(run_scheduled_task_command)
      end

      private

      def resolve_username_and_password
        local_state_file = @instance.diagnose[:state_file]

        unless config[:task_password]
          if local_state_file.key?(:password)
            config[:task_password] = local_state_file[:password]
          else
            config[:task_password] = @instance.transport[:password]
          end
        end

        unless config[:task_username
          if local_state_file.key?(:username)
            config[:task_username] = local_state_file[:username]
          else
            config[:task_username] = @instance.transport[:username]
          end
        end
      end

      def run_scheduled_task_command
        <<-EOH
        try {
          $npipeServer = new-object System.IO.Pipes.NamedPipeServerStream( 'task', [System.IO.Pipes.PipeDirection]::In)
          $pipeReader = new-object System.IO.StreamReader($npipeServer)
          schtasks /run /tn "chef-tk"
          $npipeserver.waitforconnection()
          $host.ui.writeline('Connected to the scheduled task.')
          while ($npipeserver.IsConnected) { 
            $output = $pipereader.ReadLine()
            if ($output -like 'SCHEDULED_TASK_DONE:*') {
              $exit_code = ($output -replace 'SCHEDULED_TASK_DONE:').trim()
            }
            else {
              $host.ui.WriteLine($output)
            }
          }
        }
        finally {
          $pipereader.dispose()
          $npipeserver.dispose()
          $host.setshouldexit($exit_code)
        }
        EOH
      end

      def setup_scheduled_task_command
        <<-EOH
          $cmd_path = "#{remote_path_join(config[:root_path], 'chef-client-script.ps1')}"
          $cmd_line = $executioncontext.invokecommand.expandstring("powershell -executionpolicy unrestricted -File $cmd_path")
          schtasks /create /tn "chef-tk" /ru '#{config[:task_username]}' /rp '#{config[:task_password]}' /sc daily /st 00:00 /f /tr "$cmd_line"
        EOH
      end

      def scheduled_task_command
        <<-EOH
          $pre_cmd = '$env:temp = "' + $env:temp + '"' + ";"
          $pre_cmd += 'start-sleep -seconds 5;'
          $pre_cmd += '$npipeClient = new-object System.IO.Pipes.NamedPipeClientStream( $env:ComputerName,'
          $pre_cmd += '"task", [System.IO.Pipes.PipeDirection]::Out); $npipeclient.connect();'
          $pre_cmd += '$pipeWriter = new-object System.IO.StreamWriter($npipeClient);'
          $pre_cmd += '$pipeWriter.AutoFlush = $true'
          $cmd_path = "#{remote_path_join(config[:root_path], 'chef-client-script.ps1')}"
          $cmd_to_eval = gc $cmd_path -readcount 0 | out-string
          $cmd = $executioncontext.invokecommand.expandstring($cmd_to_eval) -replace '\r\n'
          $cmd = "$cmd | " + '% {} {$pipewriter.writeline($_)} {$pipewriter.writeline("SCHEDULED_TASK_DONE: $LastExitCode");$pipewriter.dispose();$npipeclient.dispose()}'
          $pre_cmd, $cmd | out-file $cmd_path
        EOH
      end

      def prepare_client_zero_script
        cmd = [local_mode_command, *chef_client_args].join(' ')
        File.open(File.join(sandbox_path, 'chef-client-script.ps1'), 'w') do |file|
          file.write(cmd)
        end
      end

      def chef_client_args
        level = config[:log_level] == :info ? :info : config[:log_level]
        args = [
          "--config #{remote_path_join(config[:root_path], 'client.rb')}",
          "--log_level #{level}",
          '--force-formatter',
          '--no-color'
        ]
        add_optional_chef_client_args!(args)

        args
      end
    end
  end
end
