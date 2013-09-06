require_relative '../../helper'

module VagrantWindows
  module Guest
    module Cap
      class MountVirtualBoxSharedFolder
        
        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          share_name = VagrantWindows::Helper.win_friendly_share_id(name)
          mount_script = VagrantWindows.load_script_template("mount_volume.virtualbox.ps1",
            :options => {:mount_point => guestpath, :share_name => share_name})
          machine.communicate.execute(mount_script, {:shell => :powershell})
        end
      end
    end
  end
end
