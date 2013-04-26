require "#{VagrantWindows::vagrant_root}/plugins/provisioners/puppet/provisioner/puppet"

module VagrantPlugins
  module Puppet
    module Provisioner
      class Puppet < Vagrant.plugin("2", :provisioner)
        
        run_puppet_apply_on_linux = instance_method(:run_puppet_apply)
        
        # This patch is needed until Vagrant supports Puppet on Windows guests
        define_method(:run_puppet_apply) do
          is_windows ? run_puppet_apply_on_windows() : run_puppet_apply_on_linux.bind(self).()
        end
        
        def run_puppet_apply_on_windows
          options = [config.options].flatten
          module_paths = @module_paths.map { |_, to| to }
          if !@module_paths.empty?
            # Prepend the default module path
            module_paths.unshift("/etc/puppet/modules")

            # Add the command line switch to add the module path
            options << "--modulepath '#{module_paths.join(';')}'"
          end

          options << @manifest_file
          options = options.join(" ")

          # Build up the custom facts if we have any
          facter = ""
          if !config.facter.empty?
            facts = []
            config.facter.each do |key, value|
              facts << "$env:FACTER_#{key}='#{value}';"
            end

            facter = "#{facts.join(" ")} "
          end
          
          command = "cd #{manifests_guest_path}; if($?) \{ #{facter} puppet apply #{options} \}"
          
          @machine.env.ui.info I18n.t("vagrant.provisioners.puppet.running_puppet",
                                      :manifest => @manifest_file)

          @machine.communicate.sudo(command) do |type, data|
            data.chomp!
            @machine.env.ui.info(data, :prefix => false) if !data.empty?
          end
        end

        def is_windows
          @machine.config.vm.guest.eql? :windows
        end

      end # Puppet class
    end
  end
end
