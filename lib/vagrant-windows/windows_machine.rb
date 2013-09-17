module VagrantWindows
  
  # Provides a wrapper around the Vagrant machine object
  class WindowsMachine
    
    attr_reader :machine
    
    # Returns true if the specifed Vagrant machine is a Windows guest, otherwise false.
    #
    # @param [Machine] The Vagrant machine object
    # @return [Boolean]
    def self.is_windows?(machine)
      machine.config.vm.guest.eql? :windows
    end
    
    # @param [Machine] The Vagrant machine object
    def initialize(machine)
      @machine = machine
    end
    
    # Checks to see if the machine is using VMWare Fusion or Workstation.
    #
    # @return [Boolean]
    def is_vmware?()
      @machine.provider_name.to_s().start_with?('vmware')
    end
    
    # Returns the active WinRMShell for the guest.
    #
    # @return [WinRMShell]
    def winrmshell()
      @machine.communicate.winrmshell
    end

    # Reads the machine's MAC addresses keyed by interface index.
    # {1=>"0800273FAC5A", 2=>"08002757E68A"}
    #
    # @return [Hash]
    def read_mac_addresses()
      @machine.provider.driver.read_mac_addresses
    end
    
    # Returns a list of forwarded ports for a VM.
    # NOTE: For VMWare this is currently unsupported.
    #
    # @return [Array<Array>]
    def read_forwarded_ports()
      is_vmware?() ? [] : @machine.provider.driver.read_forwarded_ports
    end
    
    # Returns the SSH config for this machine.
    #
    # @return [Hash]
    def ssh_info()
      @machine.ssh_info
    end
    
    def windows_config()
      @machine.config.windows
    end
    
    def winrm_config()
      @machine.config.winrm
    end
    
  end
end