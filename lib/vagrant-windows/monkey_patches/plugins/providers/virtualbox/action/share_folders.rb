require "#{Vagrant::source_root}/plugins/providers/virtualbox/action/share_folders"
require_relative '../../../../../helper'

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class ShareFolders        
        include VagrantWindows::Helper

        alias_method :original_create_metadata, :create_metadata

        def create_metadata

          unless @env[:machine].is_windows?
            # don't change the shared folder name for linux guests.  We don't want the shared folder name of linux guests to be different
            # depending on whether the vagrant-windows plugin is installed or not.
            original_create_metadata
          else
            @env[:ui].info I18n.t("vagrant.actions.vm.share_folders.creating")

            folders = []
            shared_folders.each do |id, data|
              hostpath = File.expand_path(data[:hostpath], @env[:root_path])
              hostpath = Vagrant::Util::Platform.cygwin_windows_path(hostpath)

              folder_name = win_friendly_share_id(id.gsub(/[\/\/]/,'_').sub(/^_/, ''))

              folders << {
                  :name => folder_name,
                  :hostpath => hostpath,
                  :transient => data[:transient]
              }
            end

            @env[:machine].provider.driver.share_folders(folders)
          end
        end



      end
    end
  end
end