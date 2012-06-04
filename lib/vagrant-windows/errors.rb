module Vagrant
  module Errors
    class WINRMPortNotDetected < VagrantError
      status_code(550)
      error_key(:winrm_port_not_detected)
    end

    class WinRMInvalidShell < VagrantError
      status_code(551)
      error_key(:winrm_invalid_shell)
    end
    class WinRMTransferError < VagrantError
      status_code(552)
      error_key(:winrm_upload_error)
    end
  end
end