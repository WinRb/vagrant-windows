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

#Monkey Patch the VM object to support multiple channels
require_relative 'monkey_patches/machine'

#Add vagrant-windows plugin errors
require_relative 'errors'

#Our communication class
require_relative 'winrm'

module VagrantPlugins
  module Windows
    class Plugin < Vagrant.plugin("2")
      name "Windows guest"
      description <<-DESC
      This plugin installs a provider that allows Vagrant to manage
      Windows machines as guests.
      DESC

      config("windows") do
        require_relative "config/windows"
        Config
      end
      
      config("winrm") do
        require_relative "config/winrm"
        Config
      end
      
      guest("windows") do
        require_relative 'guest/windows'
        Guest
      end
      
      #TODO:Puppet provisioner
    end
  end
end