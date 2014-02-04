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
      @logger = Log4r::Logger.new("vagrant_windows::windows_machine")
    end

    # Returns true if this Vagrant machine is a Windows guest, otherwise false.
    #
    # @return [Boolean]
    def is_windows?()
      WindowsMachine.is_windows?(@machine)
    end
    
    # Checks to see if the machine is using VMWare Fusion or Workstation.
    #
    # @return [Boolean]
    def is_vmware?()
      @machine.provider_name.to_s().start_with?('vmware')
    end

    # Checks to see if the machine is using Parallels Desktop.
    #
    # @return [Boolean]
    def is_parallels?()
      @machine.provider_name.to_s().start_with?('parallels')
    end

    # Checks to see if the machine is using Oracle VirtualBox.
    #
    # @return [Boolean]
    def is_virtualbox?()
      @machine.provider_name.to_s().start_with?('virtualbox')
    end
    
    # Checks to see if the machine is rebooting or has a scheduled reboot.
    #
    # @return [Boolean] True if rebooting
    def is_rebooting?()
      reboot_detect_script = VagrantWindows.load_script('reboot_detect.ps1')
      @machine.communicate.execute(reboot_detect_script, :error_check => false) != 0
    end
    
    # Returns the active WinRMShell for the guest.
    #
    # @return [WinRMShell]
    def winrmshell()
      @machine.communicate.winrmshell
    end

    # Re-establishes our symbolic links if they were created between now and a reboot
    # Fixes issue #119
    def reinitialize_network_shares()
      winrmshell.powershell('& net use a-non-existant-share')
    end

    # Reads the machine's MAC addresses keyed by interface index.
    # {1=>"0800273FAC5A", 2=>"08002757E68A"}
    #
    # @return [Hash]
    def read_mac_addresses()
      @machine.provider.driver.read_mac_addresses
    end
    
    # Returns a list of forwarded ports for a VM.
    # NOTE: Only the VBox provider currently supports this method
    #
    # @return [Array<Array>]
    def read_forwarded_ports()
      if is_virtualbox?()
        @machine.provider.driver.read_forwarded_ports
      else
        []
      end
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