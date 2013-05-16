require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'

# Change to the directory of this file.
Dir.chdir(File.expand_path("../", __FILE__))

# For gem creation and bundling
require "bundler/gem_tasks"

# Install the `spec` task so that we can run tests.
RSpec::Core::RakeTask.new

# Default task is to build the gem
task :default => "build"
