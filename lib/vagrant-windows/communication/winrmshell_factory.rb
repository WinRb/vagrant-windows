require_relative 'winrmshell'
require_relative 'winrmfinder'

module VagrantWindows
  module Communication
    
    # Factory class for generating new WinRMShell instances
    class WinRMShellFactory

      # @param [WindowsMachine] The Windows machine instance
      # @param [WinRMFinder] The WinRMFinder instance
      def initialize(windows_machine, winrm_finder)
        @windows_machine = windows_machine
        @winrm_finder = winrm_finder
      end
      
      # Creates a new WinRMShell instance
      #
      # @return [WinRMShell]
      def create_winrm_shell()
        WinRMShell.new(
          @winrm_finder.winrm_host_address(),
          @windows_machine.winrm_config.username,
          @windows_machine.winrm_config.password,
          {
            :port => @winrm_finder.winrm_host_port(),
            :timeout_in_seconds => @windows_machine.winrm_config.timeout,
            :max_tries => @windows_machine.winrm_config.max_tries
          })
      end
      
    end #WinShell class
  end
end
