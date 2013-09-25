require_relative '../../helper'

module VagrantWindows
  module Guest
    module Cap
      class MountSharedFolder
        
        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          mount_shared_folder(machine, name, guestpath, "\\\\vboxsrv", options)
        end
        
        def self.mount_vmware_shared_folder(machine, name, guestpath, options)
          mount_shared_folder(machine, name, guestpath, "\\\\vmware-host\\Shared Folders", options)
        end
        
        protected
        
        def self.mount_shared_folder(machine, name, guestpath, share_vm_basepath, options)
          share_name = options[:share_name] ? options[:share_name] : name
          share_name = VagrantWindows::Helper.win_friendly_share_id(share_name)
          options = {
            :mount_point => guestpath,
            :share_name => share_name,
            :share_vm_basepath => share_vm_basepath
            }
          mount_script = VagrantWindows.load_script_template("mount_volume.ps1", :options => options)
          machine.communicate.execute(mount_script, {:shell => :powershell})
        end
        
      end
    end
  end
end
