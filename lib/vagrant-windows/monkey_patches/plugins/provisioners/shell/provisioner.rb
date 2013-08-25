require "#{Vagrant::source_root}/plugins/provisioners/shell/provisioner"
require_relative '../../../../helper'

module VagrantPlugins
  module Shell
      class Provisioner < Vagrant.plugin("2", :provisioner)
        
        include VagrantWindows::Helper

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
              # Ensure the uploaded script has a file extension, by default
              # config.upload_path from vagrant core does not
              fixed_upload_path = if File.extname(config.upload_path) == ""
                "#{config.upload_path}#{File.extname(path.to_s)}"
              else
                config.upload_path
              end
              comm.upload(path.to_s, fixed_upload_path)

              command = <<-EOH
              $old = Get-ExecutionPolicy;
              Set-ExecutionPolicy Unrestricted -force;
              #{win_friendly_path(fixed_upload_path)}#{args};
              Set-ExecutionPolicy $old -force
              EOH
              
              # Execute it with sudo
              comm.sudo(command) do |type, data|
                if [:stderr, :stdout].include?(type)
                  # Output the data with the proper color based on the stream.
                  color = type == :stdout ? :green : :red

                  @machine.ui.info(
                    data,
                    :color => color, :new_line => false, :prefix => false)
                end
              end
              
            end
          end
        end


        protected

        # This method yields the path to a script to upload and execute
        # on the remote server. This method will properly clean up the
        # script file if needed.
        def with_script_file
          if config.path
            # Just yield the path to that file...
            yield config.path
          else
            # Otherwise we have an inline script, we need to Tempfile it,
            # and handle it specially...
            file = Tempfile.new(['vagrant-powershell', '.ps1'])

            begin
              file.write(config.inline)
              file.fsync
              file.close
              yield file.path
            ensure
              file.close
              file.unlink
            end
          end
        end

        def is_windows
            @machine.config.vm.guest.eql? :windows
        end

      end # Provisioner class
  end
end
