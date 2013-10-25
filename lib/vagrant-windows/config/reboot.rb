require "vagrant"

module VagrantWindows
  module Config
    class Reboot < Vagrant.plugin("2", :config)

      attr_accessor :timeout
      attr_accessor :check_interval
      
      def initialize
        @timeout        = UNSET_VALUE
        @check_interval = UNSET_VALUE
      end

      def validate(machine)
        errors = []

        errors << "reboot.timeout cannot be nil."        if @timeout.nil?
        errors << "reboot.check_interval cannot be nil." if @check_interval.nil?

        { "Reboot" => errors }
      end

      def finalize!
        @timeout = 60        if @timeout == UNSET_VALUE
        @check_interval = 10 if @check_interval == UNSET_VALUE
      end

    end
  end
end
