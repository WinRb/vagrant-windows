require_relative '../../helper'

module VagrantWindows
  module Guest
    module Cap
      class MountSharedFolder
        
        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          mount_shared_folder(machine, name, guestpath, "\\\\vboxsrv\\")
        end
        
        def self.mount_vmware_shared_folder(machine, name, guestpath, options)
          mount_shared_folder(machine, name, guestpath, "\\\\vmware-host\\Shared Folders\\")
        end

        def self.mount_parallels_shared_folder(machine, name, guestpath, options)
          mount_shared_folder(machine, name, guestpath, "\\\\psf\\")
        end
        
        def self.mount_smb_shared_folder(machine, name, guestpath, options)
          mount_shared_folder(machine, name, guestpath, "\\\\#{options[:smb_host]}\\", options[:smb_username], options[:smb_password])
        end

        protected
        
        def self.mount_shared_folder(machine, name, guestpath, vm_provider_unc_base, username = nil, password = nil)
          share_name = VagrantWindows::Helper.win_friendly_share_id(name)
          options = {
            :mount_point => guestpath,
            :share_name => share_name,
            :vm_provider_unc_path => vm_provider_unc_base + share_name,
            :username => username,
            :password => password
          }
          mount_script = VagrantWindows.load_script_template("mount_volume.ps1", :options => options)
          machine.communicate.execute(mount_script, {:shell => :powershell})
        end
        
      end
    end
  end
end
