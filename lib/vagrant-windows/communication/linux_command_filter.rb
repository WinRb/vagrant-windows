module VagrantWindows
  module Communication
   
    # Handles loading all available Linix command filters and applying them
    # to specified command
    class LinuxCommandFilter

      # Filter the given Vagrant command to ensure compatibility with Windows
      #
      # @param [String] The Vagrant shell command
      # @returns [String] Windows runnable command or empty string
      def filter(command)
        win_friendly_cmd = command
        command_filters.each do |cmd_filter|
          win_friendly_cmd = cmd_filter.filter(win_friendly_cmd) if cmd_filter.accept?(win_friendly_cmd)
        end
        win_friendly_cmd
      end


      # All the available Linux command filters
      #
      # @returns [Array] All Linux command filter instances
      def command_filters
        @command_filters ||= create_command_filters()
      end

      # Creates all the available Linux command filters
      #
      # @returns [Array] All Linux command filter instances
      def create_command_filters
        filters = []
        Dir[File.join(File.dirname(__FILE__), '/command_filters/*.rb')].each do |file|
          require file
          clazz = File.basename(file, '.*').capitalize
          filters << Module.const_get("VagrantWindows::Communication::CommandFilters::#{clazz}").new
        end
        filters
      end

    end

  end
end
