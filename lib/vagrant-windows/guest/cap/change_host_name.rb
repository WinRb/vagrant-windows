module VagrantWindows
  module Guest
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          #### on windows, renaming a computer seems to require a reboot
          machine.communicate.execute(
            "wmic computersystem where name=\"%COMPUTERNAME%\" call rename name=\"#{name}\"",
            :shell => :cmd)
        end
      end
    end
  end
end
