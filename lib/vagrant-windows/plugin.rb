begin
  require "vagrant"
rescue LoadError
  raise "The Vagrant Windows plugin must be run within Vagrant."
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < "1.1.0"
  raise "The Vagrant Windows plugin is only compatible with Vagrant 1.1+"
end

# Add vagrant-windows plugin errors
require "vagrant-windows/errors"

# Add WinRM communication
require "vagrant-windows/winrm"

# Add Vagrant WinRM communication channel
require "vagrant-windows/communication/winrm"

# Monkey Patch the VM object to support multiple channels, i.e. WinRM
require "vagrant-windows/monkey_patches/machine"

# Add our windows specific config object
require "vagrant-windows/config/windows"

# Add our winrm specific config object
require "vagrant-windows/config/winrm"

# Add the new Vagrant Windows guest
require "vagrant-windows/guest/windows"

module VagrantPlugins
  module Windows
    class Plugin < Vagrant.plugin("2")
      name "Windows guest"
      description <<-DESC
      This plugin installs a provider that allows Vagrant to manage
      Windows machines as guests.
      DESC

      config(:windows) do
        VagrantPlugins::Windows::Config
      end
      
      config(:winrm) do
        VagrantPlugins::WinRM::Config
      end
      
      guest("windows") do
        VagrantPlugins::Windows::Guest
      end
      
      #TODO:Puppet provisioner
    end
  end
end