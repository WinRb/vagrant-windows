#Add Windows Guest Defintion
require 'vagrant-windows/guest/windows'

#Add Configuration Items
require 'vagrant-windows/config/windows'
require 'vagrant-windows/config/winrm'

# Add WinRM Communication Channel
require 'vagrant-windows/communication/winrm'

#Monkey Patch the VM object to support multiple channels
require 'vagrant-windows/monkey_patches/vm'

require 'vagrant-windows/winrm'

#Errors are good
require 'vagrant-windows/errors'

