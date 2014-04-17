require 'tempfile'
require_relative '../helper'
require_relative '../windows_machine'

module VagrantWindows
  module Provisioners

    # Builds scripts and ultimately the command to execute Chef solo or Chef client
    # on Windows guests using a scheduled task.
    class ChefCommandBuilder
      
      include VagrantWindows::Helper

      def initialize(windows_machine, chef_config, client_type)
        @windows_machine = windows_machine
        @config = chef_config

        if client_type != :solo && client_type != :client
          raise 'Invalid client_type, expected solo or client'
        end

        @client_type = client_type
      end

      def run_chef_command()
        options = {
          :command => "#{chef_binary_path} #{chef_arguments}",
          :username => @windows_machine.winrm_config.username,
          :password => @windows_machine.winrm_config.password
        }
        return VagrantWindows.load_script_template('elevated_shell.ps1', :options => options)
      end

      def chef_arguments()
        command_args = @config.arguments ? @config.arguments : ''
        chef_path = provisioning_path("#{@client_type}.rb")
        chef_dna_path = provisioning_path('dna.json')

        chef_arguments = "-c #{chef_path}"
        chef_arguments << " -j #{chef_dna_path}"
        chef_arguments << " #{command_args}"
        chef_arguments.strip
      end

      # Returns the path to the Chef binary, taking into account the
      # `binary_path` configuration option.
      def chef_binary_path()
        binary = "chef-#{@client_type}"
        return binary if !@config.binary_path
        return win_friendly_path(File.join(@config.binary_path, binary))
      end

      def provisioning_path(file_name)
        win_friendly_path("#{@config.provisioning_path}/#{file_name}")
      end

    end
  end
end