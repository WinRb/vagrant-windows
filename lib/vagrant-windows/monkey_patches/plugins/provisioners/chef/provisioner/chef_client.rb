require "#{Vagrant::source_root}/plugins/provisioners/chef/provisioner/chef_client"
require_relative '../../../../../helper'
require_relative '../../../../../windows_machine'
require_relative '../../../../../provisioners/chef_command_builder'

module VagrantPlugins
  module Chef
    module Provisioner
      class ChefClient < Base

        include VagrantWindows::Helper

        def initialize(machine, config)
          super
          @windows_machine = VagrantWindows::WindowsMachine.new(machine)
          @logger = Log4r::Logger.new("vagrant::provisioners::chef_client")
        end

        provision_on_linux = instance_method(:provision)
        run_chef_client_on_linux = instance_method(:run_chef_client)

        define_method(:run_chef_client) do
          @windows_machine.is_windows? ? run_chef_client_on_windows() : run_chef_client_on_linux.bind(self).()
        end
        
        define_method(:provision) do
          wait_if_rebooting(@windows_machine) if @windows_machine.is_windows?
          provision_on_linux.bind(self).()
        end
        
        def run_chef_client_on_windows
          if @config.run_list && @config.run_list.empty?
            @machine.ui.warn(I18n.t("vagrant.chef_run_list_empty"))
          end

          #################### START - monkey patched code ####################
          command_builder = ::VagrantWindows::Provisioners::ChefCommandBuilder.new(
            @windows_machine, @config, :client)
          
          command_builder.prepare_for_chef_run()
          command = command_builder.run_chef_command()
          ###################### END - monkey patched code ####################

          @config.attempts.times do |attempt|
            if attempt == 0
              @machine.env.ui.info I18n.t("vagrant.provisioners.chef.running_client")
            else
              @machine.env.ui.info I18n.t("vagrant.provisioners.chef.running_client_again")
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