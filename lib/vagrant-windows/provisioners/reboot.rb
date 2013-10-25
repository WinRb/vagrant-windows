require 'log4r'

module VagrantWindows
  module Provisioners
    
    # Simple "provisioner" that supports rebooting a box during a single vagrant up run
    # This ensures that the box is ready to communicate before continuing
    class Reboot < Vagrant.plugin("2", :provisioner)
      
      def initialize(machine, config)
        @logger = Log4r::Logger.new("vagrant_windows::provisioners::reboot")
        super
      end
      
      def configure(root_config)
      end
      
      def provision
        reboot_guest()
        wait_until_reboot_completes_or_times_out()
      end
      
      def cleanup
      end
      
      
      private
      
      def reboot_guest()
        @logger.info('Rebooting guest...')
        @machine.communicate.execute("Restart-Computer -Force")
      end
      
      def wait_until_reboot_completes_or_times_out()
        elapsed = 0
        begin 
          sleep @config.check_interval
          elapsed += @config.check_interval
          @logger.debug("Waiting for reboot, elapsed: #{elapsed} seconds")
        end until @machine.communicate.ready? || elapsed > @config.timeout
        
        if elapsed > @config.timeout
          @logger.warn('Timed out waiting for reboot, guest may not be ready!')
        else
          @logger.info('Reboot complete')
        end
      end
      
    end
  end
end