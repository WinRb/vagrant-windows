require_relative '../../errors'

module VagrantWindows
  module Guest
    module Cap
      class ConfigureNetworks
        def self.is_dhcp_enabled(machine, interface_index)
          cmd = "Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter \"Index=#{interface_index} and DHCPEnabled=True\""
          # FIXME: this is moronic: if we find any output in the above command,
          # then we know DHCP is enabled for that interface. This is fragile,
          # but I have not found a better way of doing this than passing a proc
          # around
          has_dhcp_enabled = false
          block = Proc.new {|type, line| if line; has_dhcp_enabled=true; end}
          machine.communicate.execute(cmd, nil, &block)
          return has_dhcp_enabled
        end

        # Useful to allow guest access from the host via a private IP on Win7
        # https://github.com/WinRb/vagrant-windows/issues/63
        def self.set_networks_to_work(machine)
          command = VagrantWindows.load_script("set_work_network.ps1")
          machine.communicate.execute(command)
        end

        def self.configure_networks(machine, networks)
          driver_mac_address = machine.provider.driver.read_mac_addresses.invert

          vm_interface_map = {}

          # NetConnectionStatus=2 -- connected
          wql = "SELECT * FROM Win32_NetworkAdapter WHERE NetConnectionStatus=2"
          machine.communicate.session.wql(wql)[:win32_network_adapter].each do |nic|
            naked_mac = nic[:mac_address].gsub(':','')
            if driver_mac_address[naked_mac]
              vm_interface_map[driver_mac_address[naked_mac]] = {
                :name => nic[:net_connection_id],
                :mac_address => naked_mac,
                :interface_index => nic[:interface_index],
                :index => nic[:index] }
            end
          end
        
          networks.each do |network|
            interface_index = vm_interface_map[network[:interface]+1][:index]

            netsh = "netsh interface ip set address \"#{vm_interface_map[network[:interface]+1][:name]}\" "
            if network[:type].to_sym == :static
              netsh = "#{netsh} static #{network[:ip]} #{network[:netmask]}"
              machine.communicate.execute(netsh)
            elsif network[:type].to_sym == :dhcp
              # Setting an interface to dhcp if already enabled causes an error
              if not is_dhcp_enabled(machine, interface_index)
                netsh = "#{netsh} dhcp"
                machine.communicate.execute(netsh)
              end
            else
              raise WindowsError, "#{network[:type]} network type is not supported, try static or dhcp"
            end
          end

          set_networks_to_work(machine) if machine.config.windows.set_work_network
          
        end # configure_networks
        
      end
    end
  end
end
