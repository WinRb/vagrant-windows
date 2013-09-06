require "#{Vagrant::source_root}/plugins/provisioners/puppet/provisioner/puppet_server"

module VagrantPlugins
  module Puppet
    module Provisioner
      class PuppetServer < Vagrant.plugin("2", :provisioner)
        
        # This patch is needed until Vagrant supports Puppet on Windows guests
        run_puppet_agent_on_linux = instance_method(:run_puppet_agent)
        
        define_method(:run_puppet_agent) do
          is_windows ? run_puppet_agent_on_windows() : run_puppet_agent_on_linux.bind(self).()
        end

        def run_puppet_agent_on_windows
          options = [config.options].flatten

          # Intelligently set the puppet node cert name based on certain external parameters
          cn = nil
          if config.puppet_node
            # If a node name is given, we use that directly for the cert name
            cn = config.puppet_node
          elsif @machine.config.vm.hostaname
            # If a host name is given, we explicitly set the certname to nil so that the hostname becomes the cert name
            cn = nil
          else
            # Otherwise, we default to the name of the box
            cn = @machine.config.vm.box
          end

          # Add the cert name option if there is one
          options += ["--certname", cn] if cn

          # Disable colors if we must
          if !@machine.env.ui.is_a?(Vagrant::UI::Colored)
            options << "--color=false"
          end

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
          
          command = "#{facter} puppet agent #{options} --server #{config.puppet_server} --detailed-exitcodes"
          
          @machine.env.ui.info I18n.t("vagrant.provisioners.puppet_server.running_puppetd",
                                      :manifest => config.puppet_server)

          @machine.communicate.sudo(command) do |type, data|
            if !data.empty?
              @machine.env.ui.info(data, :new_line => false, :prefix => false)
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
