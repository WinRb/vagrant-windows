require "vagrant"

module VagrantWindows
  module Guest
    class Windows < Vagrant.plugin("2", :guest)
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
