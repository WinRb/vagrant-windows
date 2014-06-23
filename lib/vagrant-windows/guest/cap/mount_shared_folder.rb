require_relative '../../helper'
require_relative '../../windows_machine'

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

          run_scheduled_task(machine, options, 'mount_volume', share_name)
        end

        def self.run_scheduled_task(machine, options, script_name, instance)
          windows_machine = VagrantWindows::WindowsMachine.new(machine)

          task_name = "#{script_name}_#{instance}"

          options[:user] = windows_machine.winrm_config.username
          options[:pass] = windows_machine.winrm_config.password
          options[:task_name] = "#{task_name}"
          options[:task_xml] = "/tmp/#{task_name}-task.xml"
          options[:task_ps1] = "/tmp/#{task_name}-task.ps1"
          options[:taskrun_ps1] = "/tmp/#{task_name}-taskrun.ps1"
          options[:script_ps1] = "/tmp/#{task_name}.ps1"
          options[:task_stdout_log] = "/tmp/#{task_name}-stdout.log"
          options[:task_stderr_log] = "/tmp/#{task_name}-stderr.log"
          options[:task_running] = "/tmp/#{task_name}-running.log"
          options[:task_exitcode] = "/tmp/#{task_name}-finished.log"
          options[:task_binary_path] = 'powershell'
          options[:task_arguments] = "-command ""Set-ExecutionPolicy Unrestricted -force;&'#{options[:script_ps1]}'"""

          render_file_and_upload(windows_machine, 'task.xml', options[:task_xml],
            :options => options)

          render_file_and_upload(windows_machine, 'task.ps1', options[:task_ps1],
            :options => options)

          render_file_and_upload(windows_machine, 'taskrun.ps1', options[:taskrun_ps1],
            :options => options)

          render_file_and_upload(windows_machine, "#{script_name}.ps1", options[:script_ps1],
            :options => options)

          mount_script =  <<-EOH
          $old = Get-ExecutionPolicy;
          Set-ExecutionPolicy Unrestricted -force;
          & #{options[:task_ps1]};
          Set-ExecutionPolicy $old -force;
          EOH

          machine.communicate.execute(mount_script, {:shell => :powershell})
        end

        def self.render_file_and_upload(windows_machine, script_name, dest_file, options)
          # render the script file to a local temp file and then upload
          script_local = Tempfile.new(script_name)
          IO.write(script_local, VagrantWindows.load_script_template(script_name, options))
          windows_machine.winrmshell.upload(script_local, dest_file)
        end
      end
    end
  end
end
