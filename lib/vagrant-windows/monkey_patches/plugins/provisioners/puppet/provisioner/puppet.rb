require "#{Vagrant::source_root}/plugins/provisioners/puppet/provisioner/puppet"
require_relative '../../../../../windows_machine'
require_relative '../../../../../helper'
require_relative '../../../../../errors'

module VagrantPlugins
  module Puppet
    module Provisioner
      class Puppet < Vagrant.plugin("2", :provisioner)
        
        include VagrantWindows::Helper

        # This patch is needed until Vagrant supports Puppet on Windows guests
        provision_on_linux = instance_method(:provision)
        run_puppet_apply_on_linux = instance_method(:run_puppet_apply)

        define_method(:run_puppet_apply) do
          is_windows? ? run_puppet_apply_on_windows() : run_puppet_apply_on_linux.bind(self).()
        end
        
        define_method(:provision) do
          windows_machine = VagrantWindows::WindowsMachine.new(@machine)
          wait_if_rebooting(windows_machine) if is_windows?
          provision_on_linux.bind(self).()
        end

        def run_puppet_apply_on_windows
          
          # This re-establishes our symbolic links if they were created between now and a reboot
          @machine.communicate.execute('& net use a-non-existant-share', :error_check => false)
          
          options = [@config.options].flatten
          module_paths = @module_paths.map { |_, to| to }
          if !@module_paths.empty?
            # Prepend the default module path
            module_paths.unshift("/ProgramData/PuppetLabs/puppet/etc/modules")

            # Add the command line switch to add the module path
            options << "--modulepath '#{module_paths.join(';')}'"
          end

          if @hiera_config_path
            options << "--hiera_config=#{@hiera_config_path}"
          end

          if !@machine.env.ui.is_a?(Vagrant::UI::Colored)
            options << "--color=false"
          end

          options << "--manifestdir #{manifests_guest_path}"
          options << "--detailed-exitcodes"
          options << @manifest_file
          options = options.join(" ")

          # Build up the custom facts if we have any
          facter = ""
          if !@config.facter.empty?
            facts = []
            @config.facter.each do |key, value|
              facts << "$env:FACTER_#{key}='#{value}';"
            end

            facter = "#{facts.join(" ")} "
          end

          command = "#{facter} puppet apply #{options}"
          if @config.working_directory
            command = "cd #{@config.working_directory}; if($?) \{ #{command} \}"
          end

          @machine.env.ui.info I18n.t("vagrant.provisioners.puppet.running_puppet",
                                      :manifest => @manifest_file)

          exit_status = @machine.communicate.sudo(command, :error_check => false) do |type, data|
            if !data.empty?
              @machine.env.ui.info(data, :new_line => false, :prefix => false)
            end
          end
          
          # Puppet returns 0 or 2 for success with --detailed-exitcodes
          if ![0,2].include?(exit_status)
            raise ::VagrantWindows::Errors::WinRMExecutionError,
              :shell => :powershell,
              :command => command,
              :message => "Puppet failed with an exit code of #{exit_status}"
          end
        end

        def is_windows?
          VagrantWindows::WindowsMachine.is_windows?(@machine)
        end

      end # Puppet class
    end
  end
end
