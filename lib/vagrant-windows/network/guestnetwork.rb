require 'log4r'
require_relative '../communication/winrmshell'
require_relative '../errors'

module VagrantWindows
  module Network
    
    # Manages the remote Windows guest network
    class GuestNetwork
      
      PS_GET_WSMAN_VER = '((test-wsman).productversion.split(" ") | select -last 1).split("\.")[0]'
      WQL_NET_ADAPTERS_V2 = 'SELECT * FROM Win32_NetworkAdapter WHERE MACAddress IS NOT NULL'

      attr_reader :logger
      attr_reader :winrmshell

      def initialize(winrmshell)
        @logger = Log4r::Logger.new("vagrant_windows::communication::winrmshell")
        @logger.debug("initializing WinRMShell")
        @winrmshell = winrmshell
      end
      
      # Returns an array of all NICs on the guest. Each array entry is a
      # Hash of the NICs properties.
      #
      # @return [Array]
      def network_adapters()
        wsman_version() == 2? network_adapters_v2_winrm() : network_adapters_v3_winrm()       
      end
      
      # Checks to see if the specified NIC is currently configured for DHCP.
      #
      # @return [Boolean]
      def is_dhcp_enabled(nic_index)
        has_dhcp_enabled = false
        cmd = "Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter \"Index=#{nic_index} and DHCPEnabled=True\""
        @winrmshell.powershell(cmd) do |type, line|
          has_dhcp_enabled = !line.nil?
        end
        @logger.debug("NIC #{nic_index} has DHCP enabled: #{has_dhcp_enabled}")
        has_dhcp_enabled
      end
      
      
      protected
      
      # Checks the WinRS version on the guest. Usually 2 on Windows 7/2008
      # and 3 on Windows 8/2012.
      #
      # @return [Integer]
      def wsman_version()
        @logger.debug("querying WSMan version")
        version = ''
        @winrmshell.powershell(PS_GET_WSMAN_VER) do |type, line|
          version = version + "#{line}" if type == :stdout && !line.nil?
        end
        @logger.debug("wsman version: #{version}")
        Integer(version)
      end
      
      # Returns an array of all NICs on the guest. Each array entry is a
      # Hash of the NICs properties. This method should only be used on
      # guests that have WinRS version 2.
      #
      # @return [Array]
      def network_adapters_v2_winrm()
        @logger.debug("querying network adapters")
        # Get all NICs that have a MAC address
        # http://msdn.microsoft.com/en-us/library/windows/desktop/aa394216(v=vs.85).aspx
        adapters = @winrmshell.wql(WQL_NET_ADAPTERS_V2)[:win32_network_adapter]
        @logger.debug("#{adapters.pretty_inspect}")
        return adapters
      end
      
      # Returns an array of all NICs on the guest. Each array entry is a
      # Hash of the NICs properties. This method should only be used on
      # guests that have WinRS version 3.
      #
      # This method is a workaround until the WinRM gem supports WinRS version 3.
      #
      # @return [Array]
      def network_adapters_v3_winrm()
        winrs_v3_get_adapters_ps1 = VagrantWindows.load_script("winrs_v3_get_adapters.ps1")
        output = ''
        @winrmshell.powershell(winrs_v3_get_adapters_ps1) do |type, line|
          output = output + "#{line}" if type == :stdout && !line.nil?
        end
        adapters = []
        JSON.parse(output).each do |nic|
          adapters << nic.inject({}){ |memo,(k,v)| memo[k.to_sym] = v; memo }
        end          
        @logger.debug("#{adapters.pretty_inspect}")
        return adapters
      end
        
    end #GuestNetwork class
  end
end
