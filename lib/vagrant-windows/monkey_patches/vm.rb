require "#{Vagrant::source_root}/plugins/kernel_v2/config/vm"
require "vagrant-windows/helper"

module VagrantPlugins
  module Kernel_V2
    class VMConfig < Vagrant.plugin("2", :config)
      
      include VagrantWindows::Helper
      
      # Defines a synced folder pair. This pair of folders will be synced
      # to/from the machine. Note that if the machine you're using doesn't
      # support multi-directional syncing (perhaps an rsync backed synced
      # folder) then the host is always synced to the guest but guest data
      # may not be synced back to the host.
      #
      # @param [String] hostpath Path to the host folder to share. If this
      #   is a relative path, it is relative to the location of the
      #   Vagrantfile.
      # @param [String] guestpath Path on the guest to mount the shared
      #   folder.
      # @param [Hash] options Additional options.
      def synced_folder(hostpath, guestpath, options=nil)
        options ||= {}
        options[:guestpath] = guestpath.to_s.gsub(/\/$/, '')
        options[:hostpath]  = hostpath
        
        # This line reverts the behavior of vagrant 1.2.x to vagrant 1.1.x
        # Key the share by the id. We do this because the id is a valid Windows share name
        # where the full guest path is not.
        # See vagrant issue 1742 https://github.com/mitchellh/vagrant/issues/1742
        id = win_friendly_share_id(options)

        @__synced_folders[id] = options
      end

    end
  end
end