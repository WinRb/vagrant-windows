require 'tempfile'
require "#{Vagrant::source_root}/plugins/provisioners/chef/provisioner/chef_solo"
require_relative '../../../../../helper'

module VagrantPlugins
  module Chef
    module Provisioner
      class ChefSolo < Base
        
        include VagrantWindows::Helper

        run_chef_solo_on_linux = instance_method(:run_chef_solo)

        # This patch is needed until Vagrant supports chef on Windows guests
        define_method(:run_chef_solo) do
          is_windows ? run_chef_solo_on_windows() : run_chef_solo_on_linux.bind(self).()
        end
        
        def run_chef_solo_on_windows
          # create cheftaskrun.ps1 that the scheduled task will invoke when run
          render_file_and_upload("cheftaskrun.ps1", chef_script_options[:chef_task_run_ps1], :options => chef_script_options)

          # create cheftask.xml that the scheduled task will be created with
          render_file_and_upload("cheftask.xml", chef_script_options[:chef_task_xml], :options => chef_script_options)

          # create cheftask.ps1 that will immediately invoke the scheduled task and wait for completion
          render_file_and_upload("cheftask.ps1", chef_script_options[:chef_task_ps1], :options => chef_script_options)
          
          command = <<-EOH
          $old = Get-ExecutionPolicy;
          Set-ExecutionPolicy Unrestricted -force;
          #{chef_script_options[:chef_task_ps1]};
          Set-ExecutionPolicy $old -force
          exit $LASTEXITCODE
          EOH

          @config.attempts.times do |attempt|
            if attempt == 0
              @machine.env.ui.info I18n.t("vagrant.provisioners.chef.running_solo")
            else
              @machine.env.ui.info I18n.t("vagrant.provisioners.chef.running_solo_again")
            end

            exit_status = @machine.communicate.execute(command) do |type, data|
              # Output the data with the proper color based on the stream.
              color = type == :stdout ? :green : :red

              @machine.env.ui.info(
                data, :color => color, :new_line => false, :prefix => false)
            end

            # There is no need to run Chef again if it converges
            return if exit_status == 0
          end

          # If we reached this point then Chef never converged! Error.
          raise ChefError, :no_convergence
        end
        
        def render_file_and_upload(script_name, dest_file, options)
          script_contents = VagrantWindows.load_script_template(script_name, options)

          # render cheftaskrun.ps1 to local temp file
          script_local = Tempfile.new(script_name)
          IO.write(script_local, script_contents)
          
          # upload cheftaskrun.ps1 file
          @machine.communicate.upload(script_local, dest_file)
        end
        
        def chef_script_options
          if @chef_script_options.nil?
            command_env = @config.binary_env ? "#{@config.binary_env} " : ""
            command_args = @config.arguments ? " #{@config.arguments}" : ""
            chef_solo_path = win_friendly_path(File.join(@config.provisioning_path, 'solo.rb'))
            chef_dna_path = win_friendly_path(File.join(@config.provisioning_path, 'dna.json'))
          
            chef_arguments = "-c #{chef_solo_path} "
            chef_arguments << "-j #{chef_dna_path} "
            chef_arguments << "#{command_args}"
          
            @chef_script_options = {
              :user => @machine.config.winrm.username,
              :pass => @machine.config.winrm.password,
              :chef_arguments => chef_arguments,
              :chef_task_xml => win_friendly_path("#{@config.provisioning_path}/cheftask.xml"),
              :chef_task_running => win_friendly_path("#{@config.provisioning_path}/cheftask.running"),
              :chef_task_exitcode => win_friendly_path("#{@config.provisioning_path}/cheftask.exitcode"),
              :chef_task_ps1 => win_friendly_path("#{@config.provisioning_path}/cheftask.ps1"),
              :chef_task_run_ps1 => win_friendly_path("#{@config.provisioning_path}/cheftaskrun.ps1"),
              :chef_stdout_log => win_friendly_path("#{@config.provisioning_path}/chef-solo.log"),
              :chef_stderr_log => win_friendly_path("#{@config.provisioning_path}/chef-solo.err.log"),
              :chef_binary_path => win_friendly_path("#{command_env}#{chef_binary_path("chef-solo")}")
            }
          end
          @chef_script_options
        end        
        
        def is_windows
          @machine.config.vm.guest.eql? :windows
        end
        
      end # ChefSolo class
    end
  end
end