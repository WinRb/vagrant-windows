module Vagrant
  module Errors
    class WinRMPortNotDetected < VagrantError
      #status_code(550)
      error_key(:winrm_port_not_detected)
    end

    class WinRMInvalidShell < VagrantError
      #status_code(551)
      error_key(:winrm_invalid_shell)
    end
    class WinRMTransferError < VagrantError
      #status_code(552)
      error_key(:winrm_upload_error)
    end
    class WinRMTimeout < VagrantError
      #status_code(553)
      error_key(:winrm_timeout)
    end

  end
end