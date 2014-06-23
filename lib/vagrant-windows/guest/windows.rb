require "vagrant"
require "vagrant-windows/helper"
require "vagrant-windows/guest/cap/change_host_name"
require "vagrant-windows/guest/cap/configure_networks"
require "vagrant-windows/guest/cap/halt"
require "vagrant-windows/guest/cap/mount_shared_folder"

module VagrantWindows
  module Guest
    class Windows < Vagrant.plugin("2", :guest)
      
      # Vagrant 1.1.x compatibility methods
      # Implement the 1.1.x methods and call through to the new 1.2.x capabilities
      
      attr_reader :windows_machine
      attr_reader :machine
      
      def initialize(machine = nil)
        super(machine) unless machine == nil
        @machine = machine
        @windows_machine = ::VagrantWindows::WindowsMachine.new(machine)
      end
      
      def change_host_name(name)
        VagrantWindows::Guest::Cap::ChangeHostName.change_host_name(@machine, name)
      end
      
      def distro_dispatch
        :windows
      end
      
      def halt
        VagrantWindows::Guest::Cap::Halt.halt(@machine)
      end
      
      def mount_shared_folder(name, guestpath, options)
        if @windows_machine.is_vmware?
          VagrantWindows::Guest::Cap::MountSharedFolder.mount_vmware_shared_folder(
            @machine, name, guestpath, options)
        elsif @windows_machine.is_parallels?
          VagrantWindows::Guest::Cap::MountSharedFolder.mount_parallels_shared_folder(
            @machine, name, guestpath, options)
        elsif @windows_machine.is_hyperv?
          VagrantWindows::Guest::Cap::MountSharedFolder.mount_smb_shared_folder(
            @machine, name, guestpath, options)
        else
          VagrantWindows::Guest::Cap::MountSharedFolder.mount_virtualbox_shared_folder(
            @machine, name, guestpath, options)
        end
      end
      
      def configure_networks(networks)
        VagrantWindows::Guest::Cap::ConfigureNetworks.configure_networks(@machine, networks)
      end
      
      
      # Vagrant 1.2.x compatibility methods
      
      def detect?(machine)
        
        # uname -o | grep Solaris
        # uname -s | grep 'Linux'
        # uname -s | grep 'FreeBSD'
        # cat /etc/redhat-release
        # uname -s | grep 'OpenBSD'
        # cat /etc/gentoo-release
        # cat /proc/version | grep 'Debian'
        # cat /etc/arch-release
        # cat /proc/version | grep 'Ubuntu'
        # cat /etc/SuSE-release
        # cat /etc/pld-release
        # grep 'Fedora release 1[678]' /etc/redhat-release
        
        # see if the Windows directory is present
        machine.communicate.test("test -d $Env:SystemRoot")
      end
    end
  end
end
