require 'vagrant/provisioners/chef_client'

module Vagrant
  module Provisioners
    class ChefClient < Chef
      def setup_server_config
        if env[:vm].config.vm.guest == :windows
          # force sane (Chef omnibus) defaults if these paths begin with "/"
          config.client_key_path = "C:\\opscode\\chef\\client.pem" if config.client_key_path[0] == "/"
          config.file_cache_path = "C:\\opscode\\chef\\file_store" if config.file_cache_path[0] == "/"
          config.file_backup_path = "C:\\opscode\\chef\\cache" if config.file_backup_path[0] == "/"
          config.encrypted_data_bag_secret = "C:\\opscode\\chef\\encrypted_data_bag_secret" if config.encrypted_data_bag_secret[0] == "/"
        end
        setup_config("provisioners/chef_client/client", "client.rb", {
          :node_name => config.node_name,
          :chef_server_url => config.chef_server_url,
          :validation_client_name => config.validation_client_name,
          :validation_key => guest_validation_key_path,
          :client_key => config.client_key_path,
          :file_cache_path => config.file_cache_path,
          :file_backup_path => config.file_backup_path,
          :environment => config.environment,
          :encrypted_data_bag_secret => config.encrypted_data_bag_secret
        })
      end
    end
  end
end
