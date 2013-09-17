module VagrantWindows
  
  # Provides a wrapper around the Vagrant machine object
  class WindowsMachine
    
    attr_reader :machine
    
    # @param [Machine] The Vagrant machine object
    def initialize(machine)
      @machine = machine
    end
    
    # Checks to see if the machine is using VMWare Fusion or Workstation.
    #
    # @return [Boolean]
    def is_vmware()
      @machine.provider_name.to_s().start_with?('vmware')
    end
    
    def windows_config()
      @machine.config.windows
    end
    
    def winrm_config()
      @machine.config.winrm
    end
    
  end
end