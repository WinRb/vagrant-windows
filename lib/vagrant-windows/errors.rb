require 'vagrant/errors'

module VagrantWindows
  module Errors
    
    class VagrantWindowsError < ::Vagrant::Errors::VagrantError
      error_namespace("vagrant_windows.errors")
    end  
    
    class WinRMPortNotDetected < VagrantWindowsError
      error_key(:winrm_port_not_detected)
    end

    class WinRMInvalidShell < VagrantWindowsError
      error_key(:winrm_invalid_shell)
    end
    
    class WinRMExecutionError < VagrantWindowsError
      error_key(:winrm_execution_error)
    end
    
    class WinRMAuthorizationError < VagrantWindowsError
      error_key(:winrm_auth_error)
    end    

  end
end