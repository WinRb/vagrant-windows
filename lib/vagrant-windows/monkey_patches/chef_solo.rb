require "#{Vagrant::source_root}/plugins/provisioners/chef/provisioner/chef_solo"

module VagrantPlugins
  module Chef
    module Provisioner
      class ChefSolo < Base

        run_chef_solo_on_linux = instance_method(:run_chef_solo)

        # This patch is needed until Vagrant supports chef on Windows guests
        define_method(:run_chef_solo) do
          is_windows ? run_chef_solo_on_windows() : run_chef_solo_on_linux.bind(self).()
        end
        
        def run_chef_solo_on_windows
          command_env = @config.binary_env ? "#{@config.binary_env} " : ""
          command_args = @config.arguments ? " #{@config.arguments}" : ""
          command_solo = "#{command_env}#{chef_binary_path("chef-solo")} "
          command_solo << "-c #{@config.provisioning_path}/solo.rb "
          command_solo << "-j #{@config.provisioning_path}/dna.json "
          command_solo << "#{command_args}"
          
          run_chef_src = VagrantWindows.expand_script_path("run_chef.ps1")
          @machine.communicate.upload(run_chef_src, "c:/tmp/run_chef.ps1")
          
          command = VagrantWindows.load_script_template("ps_runas.ps1",
            :options => {
              :user => machine.config.winrm.username, 
              :password => @machine.config.winrm.password,
              :cmd => "powershell.exe",
              :arguments => "-Command #{command_solo}"})

          @config.attempts.times do |attempt|
            if attempt == 0
              @machine.env.ui.info I18n.t("vagrant.provisioners.chef.running_solo")
            else
              @machine.env.ui.info I18n.t("vagrant.provisioners.chef.running_solo_again")
            end

            exit_status = @machine.communicate.sudo(command, :error_check => false) do |type, data|
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
        
        def is_windows
          @machine.config.vm.guest.eql? :windows
        end
        
      end # ChefSolo class
    end
  end
end