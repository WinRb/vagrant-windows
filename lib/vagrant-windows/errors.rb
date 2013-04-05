require 'vagrant/errors'

module VagrantWindows
  module Errors
    
    class WinRMPortNotDetected < ::Vagrant::Errors::VagrantError
      #status_code(550)
      error_key(:winrm_port_not_detected)
    end

    class WinRMInvalidShell < ::Vagrant::Errors::VagrantError
      #status_code(551)
      error_key(:winrm_invalid_shell)
    end
    
    class WinRMTransferError < ::Vagrant::Errors::VagrantError
      #status_code(552)
      error_key(:winrm_upload_error)
    end
    
    class WinRMTimeout < ::Vagrant::Errors::VagrantError
      #status_code(553)
      error_key(:winrm_timeout)
    end
    
    class WindowsError < ::Vagrant::Errors::VagrantError
      #status_code(553)
      error_namespace("vagrant.guest.windows")
      error_key(:windows_error)
    end    

  end
end