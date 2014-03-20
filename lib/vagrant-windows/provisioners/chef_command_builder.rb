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

      def prepare_for_chef_run()
        options = create_chef_options()

        # create cheftaskrun.ps1 that the scheduled task will invoke when run
        render_file_and_upload('cheftaskrun.ps1', options[:chef_task_run_ps1],
          :options => options)

        # create cheftask.xml that the scheduled task will be created with
        render_file_and_upload('cheftask.xml', options[:chef_task_xml],
          :options => options)

        # create cheftask.ps1 that will immediately invoke the scheduled task and wait for completion
        render_file_and_upload('cheftask.ps1', options[:chef_task_ps1],
          :options => options)
      end

      def run_chef_command()
        return <<-EOH
        $old = Get-ExecutionPolicy;
        Set-ExecutionPolicy Unrestricted -force;
        #{chef_task_ps1_path};
        Set-ExecutionPolicy $old -force
        EOH
      end



      def render_file_and_upload(script_name, dest_file, options)
        # render the script file to a local temp file and then upload
        script_local = Tempfile.new(script_name)
        IO.write(script_local, VagrantWindows.load_script_template(script_name, options))
        @windows_machine.winrmshell.upload(script_local, dest_file)
      end
      
      def create_chef_options
        command_env = @config.binary_env ? "#{@config.binary_env} " : ''
        return {
          :user => @windows_machine.winrm_config.username,
          :pass => @windows_machine.winrm_config.password,
          :chef_arguments => create_chef_arguments(),
          :chef_task_xml => provisioning_path('cheftask.xml'),
          :chef_task_running => provisioning_path('cheftask.running'),
          :chef_task_exitcode => provisioning_path('cheftask.exitcode'),
          :chef_task_ps1 => chef_task_ps1_path(),
          :chef_task_run_ps1 => provisioning_path('cheftaskrun.ps1'),
          :chef_stdout_log => provisioning_path("chef-#{@client_type}.log"),
          :chef_stderr_log => provisioning_path("chef-#{@client_type}.err.log"),
          :chef_binary_path => win_friendly_path("#{command_env}#{chef_binary_path}")
        }
      end

      def create_chef_arguments()
        command_args = @config.arguments ? @config.arguments : ''
        chef_path = provisioning_path("#{@client_type}.rb")
        chef_dna_path = provisioning_path('dna.json')

        chef_arguments = "-c #{chef_path}"
        chef_arguments << " -j #{chef_dna_path}"
        chef_arguments << " #{command_args}"
        chef_arguments.strip
      end

      def chef_task_ps1_path()
        provisioning_path('cheftask.ps1')
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
