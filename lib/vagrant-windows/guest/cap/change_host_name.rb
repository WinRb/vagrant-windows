module VagrantWindows
  module Guest
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          #### on windows, renaming a computer seems to require a reboot
          machine.communicate.execute(
            "netdom renamecomputer \"%COMPUTERNAME%\" /NewName:\"#{name}\" /Force /Reboot:0",
            :shell => :cmd)
        end
      end
    end
  end
end
