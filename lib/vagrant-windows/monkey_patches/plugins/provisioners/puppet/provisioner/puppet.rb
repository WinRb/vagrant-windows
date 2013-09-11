require "#{Vagrant::source_root}/plugins/provisioners/puppet/provisioner/puppet"
require_relative '../../../../../helper'


module VagrantPlugins
  module Puppet
    module Provisioner
      class Puppet < Vagrant.plugin("2", :provisioner)
        include VagrantWindows::Helper

        # This patch is needed until Vagrant supports Puppet on Windows guests
        run_puppet_apply_on_linux = instance_method(:run_puppet_apply)
        configure_on_linux = instance_method(:configure)
        
        define_method(:run_puppet_apply) do
          is_windows ? run_puppet_apply_on_windows() : run_puppet_apply_on_linux.bind(self).()
        end
        
        define_method(:configure) do |root_config|
          is_windows ? configure_on_windows(root_config) : configure_on_linux.bind(self).(root_config)
        end
        
        def run_puppet_apply_on_windows
          # create cheftaskrun.ps1 that the scheduled task will invoke when run
          render_file_and_upload("cheftaskrun.ps1", puppet_script_options[:chef_task_run_ps1], :options => puppet_script_options)

          # create cheftask.xml that the scheduled task will be created with
          render_file_and_upload("cheftask.xml", puppet_script_options[:chef_task_xml], :options => puppet_script_options)

          # create cheftask.ps1 that will immediately invoke the scheduled task and wait for completion
          render_file_and_upload("cheftask.ps1", puppet_script_options[:chef_task_ps1], :options => puppet_script_options)
          
          command = <<-EOH
          $old = Get-ExecutionPolicy;
          Set-ExecutionPolicy Unrestricted -force;
          #{puppet_script_options[:chef_task_ps1]};
          Set-ExecutionPolicy $old -force
          exit $LASTEXITCODE
          EOH

          @machine.env.ui.info I18n.t("vagrant.provisioners.puppet.running_puppet", :manifest => @manifest_file)

          exit_status = @machine.communicate.execute(command) do |type, data|
            # Output the data with the proper color based on the stream.
            color = type == :stdout ? :green : :red

            @machine.env.ui.info(
              data, :color => color, :new_line => false, :prefix => false)
          end

          raise PuppetError unless exit_status == 0
        end

        def puppet_bin_location
          exit_status = @machine.communicate.execute('where puppet', :shell => :cmd) do |type, data|
            return data
          end
          raise PuppetError unless exit_status == 0
        end
        

        def configure_on_windows(root_config)
          # Calculate the paths we're going to use based on the environment
          root_path = @machine.env.root_path
          @expanded_manifests_path = @config.expanded_manifests_path(root_path)
          @expanded_module_paths   = @config.expanded_module_paths(root_path)
          @manifest_file           = @config.manifest_file

          # Setup the module paths
          @module_paths = []
          @expanded_module_paths.each_with_index do |path, i|
            @module_paths << [path, File.join(config.temp_dir, "modules-#{i}")]
          end

          @logger.debug("Syncing folders from puppet configure")
          @logger.debug("manifests_guest_path = #{manifests_guest_path}")
          @logger.debug("expanded_manifests_path = #{@expanded_manifests_path}")
          
          # Windows guest volume mounting fails without an "id" specified
          # This hacks around that problem and allows the PS mount script to work
          root_config.vm.synced_folder(
            @expanded_manifests_path, manifests_guest_path,
            :id =>  "v-manifests-1")

          # Share the manifests directory with the guest
          #root_config.vm.synced_folder(
          #  @expanded_manifests_path, manifests_guest_path)

          # Share the module paths
          count = 0
          @module_paths.each do |from, to|
            # Sorry for the cryptic key here, but VirtualBox has a strange limit on
            # maximum size for it and its something small (around 10)
            root_config.vm.synced_folder(from, to, :id => "v-modules-#{count}")
            count += 1
          end
        end

        def is_windows
          @machine.config.vm.guest.eql? :windows
        end

        def render_file_and_upload(script_name, dest_file, options)
          script_contents = VagrantWindows.load_script_template(script_name, options)

          # render cheftaskrun.ps1 to local temp file
          script_local = Tempfile.new(script_name)
          IO.write(script_local, script_contents)
          
          # upload cheftaskrun.ps1 file
          @machine.communicate.upload(script_local, dest_file)
        end
        
        def puppet_script_options
          if @puppet_script_options.nil?
            puppet_arguments = "apply "
            puppet_arguments << "#{config.options} "
            module_paths = @module_paths.map { |_, to| win_friendly_path(to) }
            if !@module_paths.empty?
              # Prepend the default module path
              module_paths.unshift(win_friendly_path("/ProgramData/PuppetLabs/puppet/etc/modules"))

              # Add the command line switch to add the module path
              puppet_arguments << "--modulepath '#{module_paths.join(';')}' "
            end

            puppet_arguments << win_friendly_path("#{manifests_guest_path}/#{@manifest_file}")
          
            @puppet_script_options = {
              :user => @machine.config.winrm.username,
              :pass => @machine.config.winrm.password,
              :chef_arguments => puppet_arguments,
              :chef_task_name => 'puppet',
              :chef_task_xml => win_friendly_path("#{@config.temp_dir}/puppettask.xml"),
              :chef_task_running => win_friendly_path("#{@config.temp_dir}/puppettask.running"),
              :chef_task_exitcode => win_friendly_path("#{@config.temp_dir}/puppettask.exitcode"),
              :chef_task_ps1 => win_friendly_path("#{@config.temp_dir}/puppettask.ps1"),
              :chef_task_run_ps1 => win_friendly_path("#{@config.temp_dir}/puppettaskrun.ps1"),
              :chef_stdout_log => win_friendly_path("#{@config.temp_dir}/puppet.log"),
              :chef_stderr_log => win_friendly_path("#{@config.temp_dir}/puppet.err.log"),
              :chef_env_vars => Hash[config.facter.map{|key,val| ["FACTER_#{key}",val] } ],
              :chef_binary_path => win_friendly_path(puppet_bin_location())
            }
          end
          @puppet_script_options
        end        
        
        def is_windows
          @machine.config.vm.guest.eql? :windows
        end


      end # Puppet class
    end
  end
end
