require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'

# Change to the directory of this file.
Dir.chdir(File.expand_path("../", __FILE__))

# For gem creation and bundling
require "bundler/gem_tasks"

# Run the unit test suite
RSpec::Core::RakeTask.new do |task|
    task.pattern = "spec/**/*_spec.rb"
    task.rspec_opts = [ '--color', '-f documentation' ]
    task.rspec_opts << '-tunit'
end

# Run the integration test suite
RSpec::Core::RakeTask.new(:integration) do |task|
    task.pattern = "spec/**/*_spec.rb"
    task.rspec_opts = [ '--color', '-f documentation' ]
end

# Default task is to run tests
task :default => "spec"
