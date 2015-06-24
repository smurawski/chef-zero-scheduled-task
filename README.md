[![Gem Version](https://badge.fury.io/rb/chef-zero-scheduled-task.svg)](http://badge.fury.io/rb/chef-zero-scheduled-task)
# Chef::Zero::Scheduled::Task

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'chef-zero-scheduled-task'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install chef-zero-scheduled-task

## Usage

In the .kitchen.yml
```
provisioner:
  name: chef_zero_scheduled_task
```

This provisioner uses all the same configuration options as the native chef-zero provisioner, as well as:

* task_username - user account the scheduled task should run under.  (defaults to the username used for the transport)
* task_password - password to use to create the scheduled task.  (defaults to the password used for the transport)

## Contributing

1. Fork it ( https://github.com/[my-github-username]/chef-zero-scheduled-task/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
