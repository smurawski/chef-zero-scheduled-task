# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chef/zero/scheduled/task/version'

Gem::Specification.new do |spec|
  spec.name          = "chef-zero-scheduled-task"
  spec.version       = Chef::Zero::Scheduled::Task::VERSION
  spec.authors       = ["Steven Murawski"]
  spec.email         = ["steven.murawski@gmail.com"]
  spec.summary       = "Test-Kitchen Provisioner that runs Chef Zero in a Scheduled Task"
  spec.description   = "Test-Kitchen Provisioner that runs Chef Zero in a Scheduled Task"
  spec.homepage      = ""
  spec.license       = "Apache 2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry", "~> 0.10"

  spec.add_dependency "test-kitchen", "~> 1.4"
end
