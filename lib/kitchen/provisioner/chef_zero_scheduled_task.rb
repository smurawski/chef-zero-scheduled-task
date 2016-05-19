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
      
      def install_command
        warn "This provisioner has been deprecated."
        warn "This is will run the default ChefZero provisioner."
        warn "The WinRM transport in Test-Kitchen 1.8 or newer now supports using scheduled tasks to run commands."
        warn "To execute this in a scheduled task, `elvated:true` in the transport configuration."
        super
      end
      
    end
  end
end
