module VagrantWindows
  module Guest
    # A general Vagrant system implementation for "windows".
    #
    # Contributed by Chris McClimans <chris@hippiehacker.org>
    class Windows < Vagrant.plugin("2", :guest)
      
      attr_reader :machine
      
      def initialize(machine)
        super(machine)
        @machine = machine
        @logger = Log4r::Logger.new("vagrant_windows::guest::windows")
      end

      def change_host_name(name)
        @logger.info("change host name to: #{name}")
        #### on windows, renaming a computer seems to require a reboot
        @machine.communicate.execute("wmic computersystem where name=\"%COMPUTERNAME%\" call rename name=\"#{name}\"")
      end

      # TODO: I am sure that ciphering windows versions will be important at some point
      def distro_dispatch
        @logger.info("distro_dispatch: windows")
        :windows
      end

      def halt
        @machine.communicate.execute("shutdown /s /t 1 /c \"Vagrant Halt\" /f /d p:4:1")

        # Wait until the VM's state is actually powered off. If this doesn't
        # occur within a reasonable amount of time (15 seconds by default),
        # then simply return and allow Vagrant to kill the machine.
        count = 0
        while @machine.state != :poweroff
          count += 1

          return if count >= @machine.config.windows.halt_timeout
          sleep @machine.config.windows.halt_check_interval
        end
      end

      def mount_shared_folder(name, guestpath, options)
        @logger.info("mount_shared_folder: #{name}")
        mount_script = TemplateRenderer.render(File.expand_path("#{File.dirname(__FILE__)}/../scripts/mount_volume.ps1"),
                                          :options => {:mount_point => guestpath, :name => name})

        @machine.communicate.execute(mount_script,{:shell => :powershell})
      end

      def mount_nfs(ip, folders)
        raise NotImplementedError, "Mounting NFS Shares on windows is not implemented"
        # TODO: Maybe check for nfs support on the guest, since its often
        # not installed by default
        #folders.each do |name, opts|
        #  # Expand the guestpath, so we can handle things like "~/vagrant"
        #  real_guestpath = expanded_guest_path(opts[:guestpath])

          # Do the actual creating and mounting
        #  @machine.communicate.sudo("mkdir -p #{real_guestpath}")
        #  @machine.communicate.sudo("mount -o vers=#{opts[:nfs_version]} #{ip}:'#{opts[:hostpath]}' #{real_guestpath}",
        #                  :error_class => LinuxError,
        #                  :error_key => :mount_nfs_fail)
        #end
      end

      def configure_networks(networks)
        @logger.info("configure_networks: #{networks.inspect}")

        # The VBox driver 4.0 and 4.1 implement read_mac_addresses, but 4.2 does not?
        begin
          driver_mac_address = @machine.provider.driver.read_mac_addresses.invert
        rescue NoMethodError
          driver_mac_address = {}
          driver_mac_address[@machine.provider.driver.read_mac_address] = "macaddress1"
        end

        vm_interface_map = {}

        # NetConnectionStatus=2 -- connected
        wql = "SELECT * FROM Win32_NetworkAdapter WHERE NetConnectionStatus=2"
        @machine.communicate.session.wql(wql)[:win32_network_adapter].each do |nic|
          naked_mac = nic[:mac_address].gsub(':','')
          if driver_mac_address[naked_mac]
            vm_interface_map[driver_mac_address[naked_mac]] =
              { :name => nic[:net_connection_id], :mac_address => naked_mac, :index => nic[:interface_index] }
          end
        end
        
        networks.each do |network|
          netsh = "netsh interface ip set address \"#{vm_interface_map[network[:interface]+1][:name]}\" "
          if network[:type].to_sym == :static
            netsh = "#{netsh} static #{network[:ip]} #{network[:netmask]}"
          elsif network[:type].to_sym == :dhcp
            netsh = "#{netsh} dhcp"
          else
            raise WindowsError, "#{network[:type]} network type is not supported, try static or dhcp"
          end
          @machine.communicate.execute(netsh)
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
