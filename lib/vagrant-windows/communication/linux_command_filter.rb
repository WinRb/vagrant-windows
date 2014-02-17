module VagrantWindows
  module Communication

    # Filters out Linux commands or changes them to Windows equavalents
    class LinuxCommandFilter
      
      # Filter the given command into something Windows PowerShell can understand
      #
      # @param [String] The raw shell command
      # @return [String] The fixed up PS command or '' if no equivalent exists
      def filter(command)
        return '' if (command.start_with?('chmod ') || command.start_with?('chown '))
        return ps_which(command) if (command.start_with?('which '))
        return ps_rm(command) if (command.start_with?('rm '))
        return ps_test(command) if (command.start_with?('test '))
        return command
      end


      private

      def ps_which(command)
        executable = command.strip.split(/\s+/)[1]
        return <<-EOH
          $command = [Array](Get-Command #{executable} -errorAction SilentlyContinue)
          if ($null -eq $command) { exit 1 }
          write-host $command[0].Definition
          exit 0
        EOH
      end

      def ps_rm(command)
        # rm -Rf /some/dir
        # rm /some/dir
        cmd_parts = command.strip.split(/\s+/)
        dir = cmd_parts[1]
        dir = cmd_parts[2] if dir == '-Rf'
        return "rm '#{dir}' -recurse -force"
      end

      def ps_test(command)
        # test -d /tmp/dir
        # test -f /tmp/afile
        # test -L /somelink
        # test -x /tmp/some.exe
        cmd_parts = command.strip.split(/\s+/)
        return "if (Test-Path '#{cmd_parts[2]}') { exit 0 } exit 1"
      end

    end
  end
end
