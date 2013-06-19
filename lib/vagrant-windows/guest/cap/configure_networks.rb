module VagrantWindows
  module Guest
    module Cap
      class ConfigureNetworks
        
        def self.configure_networks(machine, networks)
          driver_mac_address = machine.provider.driver.read_mac_addresses.invert
          vm_interface_map = {}
          logger = Log4r::Logger.new("vagrant_windows::guest::cap::configurenetworks")

          # NetConnectionStatus=2 -- connected
          adapters = machine.communicate.session.wql("SELECT * FROM Win32_NetworkAdapter WHERE NetConnectionStatus=2")
          logger.debug("adapters: #{adapters.inspect}")
          
          adapters.each do |nic|
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
            machine.communicate.execute(netsh)
          end

          #netsh interface ip set address name="Local Area Connection" static 192.168.0.100 255.255.255.0 192.168.0.1 1
        end
      end
    end
  end
end