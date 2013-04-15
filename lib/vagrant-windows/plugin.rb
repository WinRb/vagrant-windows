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

# Add Vagrant WinRM communication channel
require "vagrant-windows/communication/winrmcommunicator"

# Monkey Patch the VM object to support multiple channels, i.e. WinRM
require "vagrant-windows/monkey_patches/machine"

# Monkey patch the Puppet provisioner to support PowerShell/Windows
require "vagrant-windows/monkey_patches/puppet"

# Add our windows specific config object
require "vagrant-windows/config/windows"

# Add our winrm specific config object
require "vagrant-windows/config/winrm"

# Add the new Vagrant Windows guest
require "vagrant-windows/guest/windows"

module VagrantWindows
  class Plugin < Vagrant.plugin("2")
    name "Windows guest"
    description <<-DESC
    This plugin installs a provider that allows Vagrant to manage
    Windows machines as guests.
    DESC
    
    guest(:windows) do
      VagrantWindows::Guest::Windows
    end
    
    config(:windows) do
      VagrantWindows::Config::Windows
    end
      
    config(:winrm) do
      VagrantWindows::Config::WinRM
    end
    
    # This initializes the internationalization strings.
    def self.setup_i18n
      I18n.load_path << File.expand_path("locales/en.yml", VagrantWindows.vagrant_windows_root)
      I18n.reload!
    end
    
    # This sets up our log level to be whatever VAGRANT_LOG is.
    def self.setup_logging
      require "log4r"

      level = nil
      begin
        level = Log4r.const_get(ENV["VAGRANT_LOG"].upcase)
      rescue NameError
        # This means that the logging constant wasn't found,
        # which is fine. We just keep `level` as `nil`. But
        # we tell the user.
        level = nil
      end

      # Some constants, such as "true" resolve to booleans, so the
      # above error checking doesn't catch it. This will check to make
      # sure that the log level is an integer, as Log4r requires.
      level = nil if !level.is_a?(Integer)

      # Set the logging level on all "vagrant" namespaced
      # logs as long as we have a valid level.
      if level
        logger = Log4r::Logger.new("vagrant_windows")
        logger.outputters = Log4r::Outputter.stderr
        logger.level = level
        logger = nil
      end
    end

  end
end

VagrantWindows::Plugin.setup_logging()
VagrantWindows::Plugin.setup_i18n()
