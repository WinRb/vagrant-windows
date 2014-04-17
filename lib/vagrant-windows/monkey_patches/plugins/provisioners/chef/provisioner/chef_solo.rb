require "#{Vagrant::source_root}/plugins/provisioners/chef/provisioner/chef_solo"
require_relative '../../../../../helper'
require_relative '../../../../../windows_machine'
require_relative '../../../../../provisioners/chef_command_builder'

module VagrantPlugins
  module Chef
    module Provisioner
      class ChefSolo < Base

        include VagrantWindows::Helper
        
        def initialize(machine, config)
          super
          @windows_machine = VagrantWindows::WindowsMachine.new(machine)
          @logger = Log4r::Logger.new("vagrant::provisioners::chef_solo")
        end

        provision_on_linux = instance_method(:provision)
        run_chef_solo_on_linux = instance_method(:run_chef_solo)

        # This patch is needed until Vagrant supports chef on Windows guests
        define_method(:run_chef_solo) do
          @windows_machine.is_windows? ? run_chef_solo_on_windows() : run_chef_solo_on_linux.bind(self).()
        end
        
        define_method(:provision) do
          wait_if_rebooting(@windows_machine) if @windows_machine.is_windows?
          provision_on_linux.bind(self).()
        end
        
        def run_chef_solo_on_windows
          
          #################### START - monkey patched code ####################
          command = ::VagrantWindows::Provisioners::ChefCommandBuilder.new(
            @windows_machine, @config, :solo).run_chef_command()
          ###################### END - monkey patched code ####################

          @config.attempts.times do |attempt|
            if attempt == 0
              @machine.env.ui.info I18n.t("vagrant.provisioners.chef.running_solo")
            else
              @machine.env.ui.info I18n.t("vagrant.provisioners.chef.running_solo_again")
            end
            
            #################### START - monkey patched code ####################
            @windows_machine.reinitialize_network_shares()
            ###################### END - monkey patched code ####################

            exit_status = @machine.communicate.execute(command, :error_check => false) do |type, data|
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
        
      end # ChefSolo class
    end
  end
end