require "vagrant"

module VagrantWindows
  module Config
    class Windows < Vagrant.plugin("2", :config)

      attr_accessor :halt_timeout
      attr_accessor :halt_check_interval
      
      def initialize
        @halt_timeout        = UNSET_VALUE
        @halt_check_interval = UNSET_VALUE
      end

      def validate(machine)
        errors = []

        errors << "windows.halt_timeout cannot be nil."        if machine.config.windows.halt_timeout.nil?
        errors << "windows.halt_check_interval cannot be nil." if machine.config.windows.halt_check_interval.nil?

        { "Windows Guest" => errors }
      end

      def finalize!
        @halt_timeout = 30       if @halt_timeout == UNSET_VALUE
        @halt_check_interval = 1 if @halt_check_interval == UNSET_VALUE
      end

    end
  end
end
