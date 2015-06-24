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
        unless config[:task_username] && config[:task_password]
          local_state_file = @instance.diagnose[:state_file]
          if local_state_file.key?(:password)
            config[:task_username] = local_state_file[:username]
            config[:task_password] = local_state_file[:password]
          else
            config[:task_username] = @instance.transport[:username]
            config[:task_password] = @instance.transport[:password]
          end
        end
      end

      def run_scheduled_task_command
        <<-EOH
          if (test-path 'c:/chef/tk.log') {
            remove-item c:/chef/tk.log -force
          }
          schtasks /run /tn "chef-tk"
          $host.ui.WriteLine('Running scheduled task chef-tk.')
          do {
            $host.ui.WriteLine('  The task is still running.')
            start-sleep -seconds 5
            $state = schtasks /query /tn chef-tk /fo csv /v | convertfrom-csv
          } while ($state.status -like 'Running')
          $host.ui.WriteLine('')
          get-content c:/chef/tk.log -readcount 0
        EOH
      end

      def setup_scheduled_task_command
        <<-EOH
          $cmd_path = "#{remote_path_join(config[:root_path], 'chef-client-script.ps1')}"
          $cmd_line = $executioncontext.invokecommand.expandstring("powershell -executionpolicy unrestricted -File $cmd_path")
          schtasks /create /tn "chef-tk" /ru #{config[:task_username]} /rp #{config[:task_password]} /sc daily /st 00:00 /f /tr "$cmd_line"
        EOH
      end

      def scheduled_task_command
        <<-EOH
          $pre_cmd = '$env:temp = "' + $env:temp + '"'
          $cmd_path = "#{remote_path_join(config[:root_path], 'chef-client-script.ps1')}"
          $cmd_to_eval = gc $cmd_path | out-string
          $cmd = $executioncontext.invokecommand.expandstring($cmd_to_eval)
          $cmd_folder = split-path $cmd_path
          if (-not (test-path $cmd_folder)) {$null = mkdir $cmd_folder}
          $pre_cmd, $cmd | out-file $cmd_path
        EOH
      end

      def prepare_client_zero_script
        cmd = [local_mode_command, *chef_client_args, '--logfile c:\chef\tk.log'].join(' ')
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
