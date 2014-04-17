module VagrantWindows
  module Communication
    module CommandFilters

      # Converts a *nix 'chown' command to a PowerShell equivalent
      class Chown

        def filter(command)
          # Not support on Windows, the communicator will skip this command
          ''
        end

        def accept?(command)
          command.start_with?('chown ')
        end

      end

    end
  end
end
