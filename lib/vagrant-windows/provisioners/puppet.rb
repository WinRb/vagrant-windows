require "#{VagrantWindows::vagrant_root}/plugins/provisioners/puppet/provisioner/puppet"

module VagrantPlugins
  module Puppet
    module Provisioner
      class Puppet < Vagrant.plugin("2", :provisioner)
        
        def run_puppet_apply
          options = [config.options].flatten
          module_paths = @module_paths.map { |_, to| to }
          if !@module_paths.empty?
            # Prepend the default module path
            module_paths.unshift("/etc/puppet/modules")

            # Add the command line switch to add the module path
            if is_windows
              options << "--modulepath '#{module_paths.join(';')}'"
            else
              options << "--modulepath '#{module_paths.join(':')}'"
            end
          end

          options << @manifest_file
          options = options.join(" ")

          # Build up the custom facts if we have any
          facter = ""
          if !config.facter.empty?
            facts = []
            config.facter.each do |key, value|
              if is_windows
                facts << "$env:FACTER_#{key}='#{value}';"
              else
                facts << "FACTER_#{key}='#{value}'"
              end
            end

            facter = "#{facts.join(" ")} "
          end
          
          if is_windows
            command = "cd #{manifests_guest_path}; if($?) \{ #{facter} puppet apply #{options} \}"
          else
            command = "cd #{manifests_guest_path} && #{facter}puppet apply #{options} --detailed-exitcodes || [ $? -eq 2 ]"
          end

          @machine.env.ui.info I18n.t("vagrant.provisioners.puppet.running_puppet",
                                      :manifest => @manifest_file)

          @machine.communicate.sudo(command) do |type, data|
            data.chomp!
            @machine.env.ui.info(data, :prefix => false) if !data.empty?
          end
        end

        def verify_binary(binary)
          if @machine.config.vm.guest.eql? :windows
            command = "command #{binary}"
          else
            command = "which #{binary}"
          end
          @machine.communicate.sudo(
            command,
            :error_class => PuppetError,
            :error_key => :not_detected,
            :binary => binary)
        end

        def verify_shared_folders(folders)
          if @machine.config.vm.guest.eql? :windows
            command = "if(-not (test-path #{folder})) \{exit 1\} "
          else
            command = "test -d #{folder}"
          end
          folders.each do |folder|
            @logger.debug("Checking for shared folder: #{folder}")
            if !@machine.communicate.test(command)
              raise PuppetError, :missing_shared_folders
            end
          end
        end
        
        def is_windows
          @machine.config.vm.guest.eql? :windows
        end

      end # Puppet class
    end
  end
end
