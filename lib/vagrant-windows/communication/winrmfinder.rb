require 'log4r'
require_relative '../errors'
require_relative '../windows_machine'

module VagrantWindows
  module Communication
    class WinRMFinder

      attr_reader :logger
      attr_reader :windows_machine
    
      def initialize(windows_machine)
        @windows_machine = windows_machine
        @logger = Log4r::Logger.new("vagrant_windows::communication::winrmfinder")
      end

      # Finds the address of the Windows machine.
      # Raises a Vagrant::Errors::SSHNotReady if WinRM is not responding yet.
      #
      # @return [String] The IP of the Windows machine
      def find_winrm_host_address
        # Get the SSH info for the machine, raise an exception if the
        # provider is saying that SSH is not ready.
        ssh_info = @windows_machine.ssh_info
        raise Vagrant::Errors::SSHNotReady if ssh_info.nil?
        @logger.info("WinRM host: #{ssh_info[:host]}")
        return ssh_info[:host]
      end
      
      # Finds the IP port of the Windows machine's WinRM service.
      #
      # @return [String] The port of the Windows machine's WinRM service
      def find_winrm_host_port
        expected_guest_port = @windows_machine.winrm_config.guest_port
        @logger.debug("Searching for WinRM port: #{expected_guest_port.inspect}")

        # Look for the forwarded port only by comparing the guest port
        @windows_machine.read_forwarded_ports().each do |_, _, hostport, guestport|
          return hostport if guestport == expected_guest_port
        end
        
        # We tried, give up and use the configured port as-is
        @windows_machine.winrm_config.port
      end
      
    end
  end
end