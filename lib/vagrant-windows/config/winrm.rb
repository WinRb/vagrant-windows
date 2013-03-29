require "vagrant"

module VagrantPlugins
  module WinRM
    class Config < Vagrant.plugin("2", :config)

      attr_accessor :username
      attr_accessor :password
      attr_accessor :host
      attr_accessor :port
      attr_accessor :guest_port
      attr_accessor :max_tries
      attr_accessor :timeout

      def initialize
        @username = "vagrant"
        @password = "vagrant"
        @guest_port = 5985
        @port = 5985
        @host = "localhost"
        @max_tries = 12
        @timeout = 1800
      end

      def validate(machine)
        errors = []
        
        [:username, :password, :host, :max_tries, :timeout].each do |field|
          errors << I18n.t("vagrant.config.common.error_empty", :field => field) if \
            !instance_variable_get("@#{field}".to_sym)
        end
        
        { "WinRM" => errors }
      end
      
    end
  end
end
