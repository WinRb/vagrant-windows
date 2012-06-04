module Vagrant
  module Config
    class Windows < Vagrant::Config::Base
      attr_accessor :winrm_user
      attr_accessor :winrm_password
      attr_accessor :halt_timeout
      attr_accessor :halt_check_interval
      attr_accessor :device
      
      def initialize
        @winrm_user = 'vagrant'
        @winrm_password = 'vagrant'
        @halt_timeout = 30
        @halt_check_interval = 1
        @device = "e1000g"
      end

      def validate(env, errors)
        [ :winrm_user, :winrm_password, :host, :max_tries, :timeout].each do |field|
          errors.add(I18n.t("vagrant.config.common.error_empty", :field => field)) if !instance_variable_get("@#{field}".to_sym)
        end
      end
    end
  end
end

Vagrant.config_keys.register(:windows) { Vagrant::Config::Windows }