module VagrantWindows
  module Guest
    module Cap
      class Halt
        def self.halt(machine)
          machine.communicate.execute("shutdown /s /t 1 /c \"Vagrant Halt\" /f /d p:4:1")

          # Wait until the VM's state is actually powered off. If this doesn't
          # occur within a reasonable amount of time (15 seconds by default),
          # then simply return and allow Vagrant to kill the machine.
          count = 0
          while machine.state != :poweroff
            count += 1

            return if count >= machine.config.windows.halt_timeout
            sleep machine.config.windows.halt_check_interval
          end
        end
      end
    end
  end
end
