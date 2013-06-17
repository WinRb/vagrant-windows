module VagrantWindows
  module Guest
    module Cap
      class MountVirtualBoxSharedFolder
        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          # Vagrant includes a leading '/' which isn't a valid Windows share name
          mount_script = VagrantWindows.load_script_template("mount_volume.ps1",
            :options => {:mount_point => guestpath, :share_name => name})
          machine.communicate.execute(mount_script, {:shell => :powershell})
        end
      end
    end
  end
end
