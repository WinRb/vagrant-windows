require "#{Vagrant::source_root}/plugins/provisioners/chef/provisioner/chef_solo"
require 'tempfile'

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
          deploy_cheftaskrun_ps1()
          deploy_cheftask_xml()
          deploy_cheftask_ps1()

          @config.attempts.times do |attempt|
            if attempt == 0
              @machine.env.ui.info I18n.t("vagrant.provisioners.chef.running_solo")
            else
              @machine.env.ui.info I18n.t("vagrant.provisioners.chef.running_solo_again")
            end

            exit_status = @machine.communicate.sudo(remote_cheftask_ps1_path(), :error_check => false) do |type, data|
              # Output the data with the proper color based on the stream.
              color = type == :stdout ? :green : :red

              # Note: Be sure to chomp the data to avoid the newlines that the
              # Chef outputs.
              @machine.env.ui.info(data.chomp, :color => color, :prefix => false)
            end

            # There is no need to run Chef again if it converges
            return if exit_status == 0
          end

          # If we reached this point then Chef never converged! Error.
          raise ChefError, :no_convergence
        end
        
        def deploy_cheftaskrun_ps1
          # create cheftaskrun.ps1 that the scheduled task will invoke when run          
          chef_arguments = "-c #{@config.provisioning_path}/solo.rb "
          chef_arguments << "-j #{@config.provisioning_path}/dna.json "
          chef_arguments << "#{command_args}"
          
          render_file_and_upload("cheftaskrun.ps1", remote_cheftaskrun_ps1_path(), :options => {
            :chef_task_running => remote_chef_task_running_path(), 
            :chef_stdout_log => remote_chef_stdout_log_path(),
            :chef_stderr_log => win_friendly_path("#{@config.provisioning_path}/chef-solo.err.log"),
            :chef_binary_path => win_friendly_path("#{command_env}#{chef_binary_path("chef-solo")}"),
            :chef_arguments => chef_arguments })
        end
        
        def deploy_cheftask_xml
          # create cheftask.xml that the scheduled task will be created with
          render_file_and_upload("cheftask.xml", remote_cheftask_xml_path() :options => {
            :run_chef_path => remote_cheftaskrun_ps1_path() })
        end
        
        def deploy_cheftask_ps1
          # create cheftask.ps1 that will immediately invoke the scheduled task and wait for completion
          render_file_and_upload("cheftask.ps1", remote_cheftask_ps1_path() :options => {
            :chef_task_xml => remote_cheftask_xml_path(),
            :user => @machine.config.winrm.username,
            :pass => @machine.config.winrm.password,
            :chef_task_running => remote_chef_task_running_path(),
            :chef_stdout_log => remote_chef_stdout_log_path() })
        end
        
        def render_file_and_upload(script_name, dest_file, options)
          script_contents = VagrantWindows.load_script_template(script_name, options)

          # render cheftaskrun.ps1 to local temp file
          script_local = Tempfile.new(script_name)
          IO.write(script_contents, script_local)
          
          # upload cheftaskrun.ps1 file
          @machine.communicate.upload(script_local, dest_file)
        end
        
        def remote_cheftaskrun_ps1_path
          win_friendly_path("#{@config.provisioning_path}/cheftaskrun.ps1"))
        end
        
        def remote_cheftask_xml_path
          win_friendly_path("#{@config.provisioning_path}/cheftask.xml"))
        end
        
        def remote_cheftask_ps1_path
          win_friendly_path("#{@config.provisioning_path}/cheftask.ps1"))
        end
        
        def remote_chef_task_running_path
          win_friendly_path("#{@config.provisioning_path}/cheftask.running")
        end
        
        def remote_chef_stdout_log_path
          win_friendly_path("#{@config.provisioning_path}/chef-solo.log")
        end
        
        def is_windows
          @machine.config.vm.guest.eql? :windows
        end
        
      end # ChefSolo class
    end
  end
end