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
            options << module_path_options()
          end

          options << @manifest_file
          options = options.join(" ")

          # Build up the custom facts if we have any
          facter = ""
          if !config.facter.empty?
            facts = []
            config.facter.each do |key, value|
              facts << create_facter_key_value(key, value)
            end

            facter = "#{facts.join(" ")} "
          end
          
          command = puppet_cmd(facter, options)
          
          @machine.env.ui.info I18n.t("vagrant.provisioners.puppet.running_puppet",
                                      :manifest => @manifest_file)

          @machine.communicate.sudo(command) do |type, data|
            data.chomp!
            @machine.env.ui.info(data, :prefix => false) if !data.empty?
          end
        end

        def verify_binary(binary)
          @machine.communicate.sudo(
            verify_binary_cmd,
            :error_class => PuppetError,
            :error_key => :not_detected,
            :binary => binary)
        end

        def verify_shared_folders(folders)
          folders.each do |folder|
            @logger.debug("Checking for shared folder: #{folder}")
            if !@machine.communicate.test(verify_shared_folders_cmd)
              raise PuppetError, :missing_shared_folders
            end
          end
        end
        
        def puppet_cmd(facter, options)
          if is_windows
            "cd #{manifests_guest_path}; if($?) \{ #{facter} puppet apply #{options} \}"
          else
            "cd #{manifests_guest_path} && #{facter}puppet apply #{options} --detailed-exitcodes || [ $? -eq 2 ]"
          end
        end
        
        def create_facter_key_value(key, value)
          is_windows ? "$env:FACTER_#{key}='#{value}';" : "FACTER_#{key}='#{value}'"
        end
        
        def module_path_options
          # windows uses ';' instead of ':'
          is_windows ? "--modulepath '#{module_paths.join(';')}'" : "--modulepath '#{module_paths.join(':')}'"
        end
        
        def verify_binary_cmd
          is_windows ? "command #{binary}" : "which #{binary}"
        end
        
        def verify_shared_folders_cmd
          is_windows ? "if(-not (test-path #{folder})) \{exit 1\} " : "test -d #{folder}"
        end
        
        def is_windows
          @machine.config.vm.guest.eql? :windows
        end

      end # Puppet class
    end
  end
end
