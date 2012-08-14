module Vagrant
  module Guest
    # A general Vagrant system implementation for "windows".
    #
    # Contributed by Chris McClimans <chris@hippiehacker.org>
    class Windows < Base
      # A custom config class which will be made accessible via `config.windows`
      # Here for whenever it may be used.
      class WindowsError < Errors::VagrantError
        error_namespace("vagrant.guest.windows")
      end

      def change_host_name(name)
        #### on windows, renaming a computer seems to require a reboot
	@vm.channel.run_cmd("netdom renamecomputer %COMPUTERNAME% /force /reb:2 /newname:#{name.split('.')[0]}")
        sleep @vm.config.windows.halt_check_interval
	@vm.channel.execute("hostname")
      end

      # TODO: I am sure that ciphering windows versions will be important at some point
      def distro_dispatch
        # current implementation of winrm just "runs a thing and returns the exit status."  there's no way to get stdout/stderr.
        # this means that testing for versions has to happen remotely or you have to write the version out as a file and then pull it down.
        # writing a bunch of remotely-executed WMI tests seems dumb, but it should be effective.
        # however, on my host this code returns "invalid query" despite the fact that a copy/paste of the command works on the guest.
        # need someone else to verify that this is, in fact, a code problem and not an issue with my environment.
        begin
          resp = @vm.channel.wmi("select * from Win32_OperatingSystem")[:xml_fragment][:win32_operating_system][0]
          # resp is now a bucket that contains all the keys of Win32_OperatingSystem, which should get you architecture + build info.  good luck.
       	  :windows2008r2 if resp[:version] == "6.1.7601" or resp[:caption] =~ /Microsoft Windows Server 2008 R2/
          :windows
        rescue
          :windows
        end
      end

      def halt
        @vm.channel.execute("shutdown /s /t 1 /c \"Vagrant Halt\" /f /d p:4:1")

        # Wait until the VM's state is actually powered off. If this doesn't
        # occur within a reasonable amount of time (15 seconds by default),
        # then simply return and allow Vagrant to kill the machine.
        count = 0
        while @vm.state != :poweroff
          count += 1

          return if count >= @vm.config.windows.halt_timeout
          sleep @vm.config.windows.halt_check_interval
        end
      end

      def mount_shared_folder(name, guestpath, options)
        mount_script = TemplateRenderer.render(File.expand_path("#{File.dirname(__FILE__)}/../scripts/mount_volume.ps1"),
                                          :options => {:mount_point => guestpath, :name => name})

        @vm.channel.execute(mount_script,{:shell => :powershell})
      end

      def mount_nfs(ip, folders)
        raise NotImplementedError, "Mounting NFS Shares on windows is not implemented"
        # TODO: Maybe check for nfs support on the guest, since its often
        # not installed by default
        #folders.each do |name, opts|
        #  # Expand the guestpath, so we can handle things like "~/vagrant"
        #  real_guestpath = expanded_guest_path(opts[:guestpath])

          # Do the actual creating and mounting
        #  @vm.channel.sudo("mkdir -p #{real_guestpath}")
        #  @vm.channel.sudo("mount -o vers=#{opts[:nfs_version]} #{ip}:'#{opts[:hostpath]}' #{real_guestpath}",
        #                  :error_class => LinuxError,
        #                  :error_key => :mount_nfs_fail)
        #end
      end

      def configure_networks(networks)
        ### HACK!!!!! 
        Nori.advanced_typecasting = false
        if driver_mac_address = @vm.driver.read_mac_addresses
          driver_mac_address = driver_mac_address.invert
        end

        vm_interface_map = {}
        @vm.channel.session.wql("SELECT * FROM Win32_NetworkAdapter WHERE NetConnectionStatus=2")[:win32_network_adapter].each do |nic|
          naked_mac = nic[:mac_address].gsub(':','')
          if driver_mac_address[naked_mac]
            vm_interface_map[driver_mac_address[naked_mac]] = { :name => nic[:net_connection_id], :mac_address => naked_mac, :index => nic[:interface_index] }
          end
        end
        puts networks
        puts vm_interface_map
        networks.each do |network|
          if network[:type].to_sym == :static
              vm.channel.execute("netsh interface ip set address \"#{vm_interface_map[network[:interface]+1][:name]}\" static #{network[:ip]} #{network[:netmask]}")
          elsif network[:type].to_sym == :dhcp
            vm.channel.execute("netsh interface ip set address \"#{vm_interface_map[network[:interface]+1][:name]}\" dhcp")
          end
        end

        #netsh interface ip set address name="Local Area Connection" static 192.168.0.100 255.255.255.0 192.168.0.1 1
        
      end


      def windows_path(path)
        p = ''
        if path =~ /^\//
          p << 'C:\\'
        end
        p << path
        p.gsub! /\//, "\\"
        p.gsub /\\\\{0,}/, "\\"
      end



    end
  end
end

Vagrant.guests.register(:windows)  { Vagrant::Guest::Windows }
