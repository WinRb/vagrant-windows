#Add Windows Guest Defintion
require 'vagrant-windows/guest/windows'
require 'vagrant-windows/guest/windows2003'
require 'vagrant-windows/guest/windows2008r2'

#Add Configuration Items
require 'vagrant-windows/config/windows'
require 'vagrant-windows/config/winrm'

# Add WinRM Communication Channel
require 'vagrant-windows/communication/winrm'

#Monkey Patch the VM object to support multiple channels
require 'vagrant-windows/monkey_patches/vm'

#Monkey Patch the driver to support returning a mapping of mac addresses to nics
require 'vagrant-windows/monkey_patches/driver'

#Monkey Patch the Chef and Chef Client providers to be Windows-path-aware
require 'vagrant-windows/monkey_patches/chef'
require 'vagrant-windows/monkey_patches/chefclient'

require 'vagrant-windows/winrm'

#Errors are good
require 'vagrant-windows/errors'

