require 'log4r'
require_relative '../errors'

module VagrantWindows
  module Communication
    class WinRMFinder

      attr_reader :logger
      attr_reader :machine
    
      def initialize(machine)
        @machine = machine
        @logger = Log4r::Logger.new("vagrant_windows::communication::winrmfinder")
      end

      def winrm_host_address
        # Get the SSH info for the machine, raise an exception if the
        # provider is saying that the machine is not ready.
        ssh_info = @machine.ssh_info
        raise VagrantWindows::Errors::WinRMNotReady if ssh_info.nil?
        
        # if the configuration has a host value, that takes precedence
        host = @machine.config.winrm.host || ssh_info[:host]
        @logger.info("WinRM host: #{host}")
        host
      end
      
      def winrm_host_port
        expected_guest_port = @machine.config.winrm.guest_port
        @logger.debug("Searching for WinRM port: #{expected_guest_port.inspect}")

        # Look for the forwarded port only by comparing the guest port
        begin
          @machine.provider.driver.read_forwarded_ports.each do |_, _, hostport, guestport|
            return hostport if guestport == expected_guest_port
          end
        rescue NoMethodError => e
          # VMWare provider doesn't support read_forwarded_ports
          @logger.debug(e.message)
        end
        
        # We tried, give up and use the configured port as-is
        @machine.config.winrm.port
      end
      
    end
  end
end
