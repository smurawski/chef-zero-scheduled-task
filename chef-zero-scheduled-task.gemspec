# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chef/zero/scheduled/task/version"

Gem::Specification.new do |spec|
  spec.name          = "chef-zero-scheduled-task"
  spec.version       = Chef::Zero::Scheduled::Task::VERSION
  spec.authors       = ["Steven Murawski"]
  spec.email         = ["steven.murawski@gmail.com"]
  spec.summary       = "Test-Kitchen Provisioner that runs Chef Zero in a Scheduled Task"
  spec.description   = "Test-Kitchen Provisioner that runs Chef Zero in a Scheduled Task"
  spec.homepage      = "https://github.com/smurawski/chef-zero-scheduled-task"
  spec.license       = "Apache 2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "test-kitchen", "~> 1.8"

  spec.add_development_dependency "pry"

  spec.add_development_dependency "bundler",   "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_development_dependency "aruba",     "~> 0.7.0"
  spec.add_development_dependency "fakefs",    "~> 0.4"
  spec.add_development_dependency "minitest",  "~> 5.3"
  spec.add_development_dependency "mocha",     "~> 1.1"

  spec.add_development_dependency "countloc",  "~> 0.4"
  spec.add_development_dependency "maruku",    "~> 0.6"
  spec.add_development_dependency "simplecov", "~> 0.7"
  spec.add_development_dependency "yard",      "~> 0.8"

  # style and complexity libraries are tightly version pinned as newer releases
  # may introduce new and undesireable style choices which would be immediately
  # enforced in CI
  spec.add_development_dependency "finstyle",  "1.5.0"
  spec.add_development_dependency "cane",      "2.6.2"

end
