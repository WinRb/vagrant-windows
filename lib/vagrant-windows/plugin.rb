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

if Vagrant::VERSION >= "1.2.0"
  # Monkey Patch the virtualbox share_folders action to make valid share names on windows
  require_relative "monkey_patches/plugins/providers/virtualbox/action/share_folders"
end

# Monkey patch the vbox42 driver to support read mac addresses
require_relative "monkey_patches/plugins/providers/virtualbox/driver/version_4_2"

# Monkey Patch the VM object to support multiple channels, i.e. WinRM
require_relative "monkey_patches/lib/vagrant/machine"

# Monkey patch the Puppet provisioners to support PowerShell/Windows
require_relative "monkey_patches/plugins/provisioners/puppet/provisioner/puppet"
require_relative "monkey_patches/plugins/provisioners/puppet/provisioner/puppet_server"

# Monkey patch the Chef provisioners to support PowerShell/Windows
require_relative "monkey_patches/plugins/provisioners/chef/provisioner/chef_solo"
require_relative "monkey_patches/plugins/provisioners/chef/provisioner/chef_client"

# Monkey patch the shell provisioner to support PowerShell/batch/exe/Windows/etc
require_relative "monkey_patches/plugins/provisioners/shell/provisioner"


module VagrantWindows
  class Plugin < Vagrant.plugin("2")
    name "Windows guest"
    description <<-DESC
    This plugin installs a provider that allows Vagrant to manage
    Windows machines as guests.
    DESC

    config(:windows) do
      require_relative "config/windows"
      VagrantWindows::Config::Windows
    end

    config(:winrm) do
      require_relative "config/winrm"
      VagrantWindows::Config::WinRM
    end

    guest(:windows) do
      require_relative "guest/windows"
      VagrantWindows::Guest::Windows
    end

    # Vagrant 1.2 introduced the concept of capabilities instead of implementing
    # an interface on the guest.
    if Vagrant::VERSION >= "1.2.0"

      guest_capability(:windows, :change_host_name) do
        require_relative "guest/cap/change_host_name"
        VagrantWindows::Guest::Cap::ChangeHostName
      end

      guest_capability(:windows, :configure_networks) do
        require_relative "guest/cap/configure_networks"
        VagrantWindows::Guest::Cap::ConfigureNetworks
      end

      guest_capability(:windows, :halt) do
        require_relative "guest/cap/halt"
        VagrantWindows::Guest::Cap::Halt
      end

      guest_capability(:windows, :mount_virtualbox_shared_folder) do
        require_relative "guest/cap/mount_virtualbox_shared_folder"
        VagrantWindows::Guest::Cap::MountVirtualBoxSharedFolder
      end

      guest_capability(:windows, :mount_vmware_shared_folder) do
        require_relative "guest/cap/mount_vmware_shared_folder"
        VagrantWindows::Guest::Cap::MountVMwareSharedFolder
      end
    
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
