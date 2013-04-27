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
        
        def configure(root_config)
          # Calculate the paths we're going to use based on the environment
          root_path = @machine.env.root_path
          @expanded_manifests_path = @config.expanded_manifests_path(root_path)
          @expanded_module_paths   = @config.expanded_module_paths(root_path)
          @manifest_file           = @config.manifest_file

          # Setup the module paths
          @module_paths = []
          @expanded_module_paths.each_with_index do |path, i|
            @module_paths << [path, File.join(config.pp_path, "modules-#{i}")]
          end

          @logger.debug("Syncing folders from puppet configure")
          @logger.debug("manifests_guest_path = #{manifests_guest_path}")
          @logger.debug("expanded_manifests_path = #{@expanded_manifests_path}")
          
          # Windows guest volume mounting fails without an "id" specified
          root_config.vm.synced_folder(
            @expanded_manifests_path, manifests_guest_path,
            :id =>  "v-manifests-1")

          # Share the manifests directory with the guest
          #root_config.vm.synced_folder(
          #  @expanded_manifests_path, manifests_guest_path)

          # Share the module paths
          count = 0
          @module_paths.each do |from, to|
            # Sorry for the cryptic key here, but VirtualBox has a strange limit on
            # maximum size for it and its something small (around 10)
            root_config.vm.synced_folder(from, to)
            count += 1
          end
        end

        def is_windows
          @machine.config.vm.guest.eql? :windows
        end

      end # Puppet class
    end
  end
end
