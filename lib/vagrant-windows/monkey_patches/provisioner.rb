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
            fixed_upload_path  = "#{config.upload_path}.ps1".gsub('/','\\')
            command = "$old = Get-ExecutionPolicy;Set-ExecutionPolicy Unrestricted -force;\& #{fixed_upload_path};Set-ExecutionPolicy $old -force"

            with_script_file do |path|
            # Upload the script to the machine
            @machine.communicate.tap do |comm|
                comm.upload(path.to_s, config.upload_path)

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
