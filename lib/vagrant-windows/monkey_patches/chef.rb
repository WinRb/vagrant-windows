require 'vagrant/provisioners/chef'

module Vagrant
  module Provisioners
    class Chef < Base
      # done because I believe provisioning_path is a path on the guest.
      def initialize(env, config)
        super
        config.provisioning_path ||= env[:vm].config.vm.guest == :windows ? "C:\\opscode\\chef" : "/etc/chef"
      end

      # done to use Windows-specific filename/pathing structure during
      # command execution but Ruby-style forward slashes in templates elsewhere.
      def setup_config(template, filename, template_vars)
        if env[:vm].config.vm.guest == :windows
           tvars = Hash[template_vars.map{ |k,v| [k, v.class == String ? v.gsub("\\",'/') : v] }]
        else
           tvars = template_vars
        end
        config_file = TemplateRenderer.render(template, {
          :log_level => :warn,
          :http_proxy => config.http_proxy,
          :http_proxy_user => config.http_proxy_user,
          :http_proxy_pass => config.http_proxy_pass,
          :https_proxy => config.https_proxy,
          :https_proxy_user => config.https_proxy_user,
          :https_proxy_pass => config.https_proxy_pass,
          :no_proxy => config.no_proxy
        }.merge(tvars))

        env[:ui].info 'chef client.rb rendered as:'
        env[:ui].info config_file.to_s

        # Create a temporary file to store the data so we
        # can upload it
        temp = Tempfile.new("vagrant")
        temp.write(config_file)
        temp.close

        remote_file = File.join(config.provisioning_path, filename)
        remote_file.gsub!('/','\\') if env[:vm].config.vm.guest == :windows
        env[:vm].channel.sudo("rm #{remote_file}", :error_check => false)
        env[:vm].channel.upload(temp.path, remote_file)
      end

      # uploading this file has to use forward slashes on a Windows guest.
      def setup_json
        env[:ui].info I18n.t("vagrant.provisioners.chef.json")

        # Set up our configuration that is passed to the attributes by default
        data = { :config => env[:global_config].to_hash }

        # Add our default share directory if it exists
        default_share = env[:vm].config.vm.shared_folders["v-root"]
        data[:directory] = default_share[:guestpath] if default_share

        # And wrap it under the "vagrant" namespace
        data = { :vagrant => data }

        # Merge with the "extra data" which isn't put under the
        # vagrant namespace by default
        data.merge!(config.merged_json)

        json = data.to_json

        # Create a temporary file to store the data so we
        # can upload it
        temp = Tempfile.new("vagrant")
        temp.write(json)
        temp.close

        remote_file = File.join(config.provisioning_path, "dna.json")
        if env[:vm].config.vm.guest == :windows
          remote_file.gsub!('/','\\') 
        end

        env[:vm].channel.upload(temp.path, remote_file )
      end

    end
  end
end

