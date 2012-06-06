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
        vm.channel.execute("wmic computersystem where name=\"%COMPUTERNAME%\" call rename name=\"#{name}\"")
      end

      # TODO: I am sure that ciphering windows versions will be important at some point
      def distro_dispatch
        :windows
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
        raise NotImplementedError, "Advanced Networking is not supported"
        # First, remove any previous network modifications
        # from the interface file.
        #vm.channel.sudo("sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/network/interfaces > /tmp/vagrant-network-interfaces")
        #vm.channel.sudo("su -c 'cat /tmp/vagrant-network-interfaces > /etc/network/interfaces'")
        #vm.channel.sudo("rm /tmp/vagrant-network-interfaces")

        # Accumulate the configurations to add to the interfaces file as
        # well as what interfaces we're actually configuring since we use that
        # later.
        #interfaces = Set.new
        #entries = []
        #networks.each do |network|
        #  interfaces.add(network[:interface])
        #  entry = TemplateRenderer.render("guests/debian/network_#{network[:type]}",
        #                                  :options => network)

        #  entries << entry
        #end

        # Perform the careful dance necessary to reconfigure
        # the network interfaces
        #temp = Tempfile.new("vagrant")
        #temp.binmode
        #temp.write(entries.join("\n"))
        #temp.close

        #vm.channel.upload(temp.path, "/tmp/vagrant-network-entry")

        # Bring down all the interfaces we're reconfiguring. By bringing down
        # each specifically, we avoid reconfiguring eth0 (the NAT interface) so
        # SSH never dies.
        #interfaces.each do |interface|
        #  vm.channel.sudo("/sbin/ifdown eth#{interface} 2> /dev/null")
        #end

        #vm.channel.sudo("cat /tmp/vagrant-network-entry >> /etc/network/interfaces")
        #vm.channel.sudo("rm /tmp/vagrant-network-entry")

        # Bring back up each network interface, reconfigured
        #interfaces.each do |interface|
        #  vm.channel.sudo("/sbin/ifup eth#{interface}")
        #end
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