require "#{VagrantWindows::vagrant_root}/plugins/provisioners/shell/provisioner"

module VagrantPlugins
  module Shell
      class Provisioner < Vagrant.plugin("2", :provisioner)

        # This patch is needed until Vagrant supports Puppet on Windows guests
        provision_on_linux = instance_method(:provision)
        
        define_method(:provision) do
          is_windows ? provision_on_windows() : provision_on_linux.bind(self).()
        end

        def provision_on_windows
            args = ""
            args = " #{config.args}" if config.args

            with_script_file do |path|
            # Upload the script to the machine
            @machine.communicate.tap do |comm|
                # Do the best effor to found what type of script or file is
                # to set ot the upload_path 
                ext = File.extname(path.to_s)
                fixed_upload_path  = "#{config.upload_path}#{ext}"
                comm.upload(path.to_s, fixed_upload_path)

                execution_upload_path  = "#{fixed_upload_path}".gsub('/','\\')
                command = "$old = Get-ExecutionPolicy;Set-ExecutionPolicy Unrestricted -force;#{execution_upload_path}#{args};Set-ExecutionPolicy $old -force"
                # Execute it with sudo
                comm.sudo(command) do |type, data|
                if [:stderr, :stdout].include?(type)
                    # Output the data with the proper color based on the stream.
                    color = type == :stdout ? :green : :red

                    # Note: Be sure to chomp the data to avoid the newlines that the
                    # Chef outputs.
                    @machine.env.ui.info(data.chomp, :color => color, :prefix => false)
                end
                end
            end
            end
        end


        def is_windows
            @machine.config.vm.guest.eql? :windows
        end

      end # Provisioner class
  end
end
