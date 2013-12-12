require "#{Vagrant::source_root}/plugins/providers/virtualbox/synced_folder"
require_relative '../../../../helper'

module VagrantPlugins
  module ProviderVirtualBox
    
    class SyncedFolder < Vagrant.plugin("2", :synced_folder)
      include VagrantWindows::Helper
      
      vagrant_prepare = instance_method(:prepare)
      
      define_method(:prepare) do |machine, folders, _opts|
        if VagrantWindows::WindowsMachine.is_windows?(machine)
          windows_folders = {}
          folders.each do |id, data|
            windows_id = win_friendly_share_id(id.gsub(/[\/\/]/,'_').sub(/^_/, ''))
            windows_folders[windows_id] = data
          end
          folders = windows_folders
        end
        vagrant_prepare.bind(self).(machine, folders, _opts)
      end

    end

  end
end