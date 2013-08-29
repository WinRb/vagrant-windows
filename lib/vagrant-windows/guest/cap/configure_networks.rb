require 'log4r'
require_relative '../../communication/guestnetwork'
require_relative '../../communication/winrmshell'
require_relative '../../errors'

module VagrantWindows
  module Guest
    module Cap
      class ConfigureNetworks
        
        @@logger = Log4r::Logger.new("vagrant_windows::guest::cap::configure_networks")
        
        def self.configure_networks(machine, networks)
          @@logger.debug("networks: #{networks.inspect}")
          
          guest_network = ::VagrantWindows::Communication::GuestNetwork.new(machine.communicate.winrmshell)

          if (machine.provider_name != :vmware_fusion) && (machine.provider_name != :vmware_workstation)
            vm_interface_map = create_vm_interface_map(machine, guest_network)
          end
          
          networks.each do |network|
            interface = vm_interface_map[network[:interface]+1]
            if interface.nil?
              @@logger.warn("Could not find interface for network #{network.inspect}")
              next
            end
            network_type = network[:type].to_sym
            if network_type == :static
              guest_network.configure_static_interface(
                interface[:index],
                interface[:net_connection_id],
                network[:ip],
                network[:netmask])
            elsif network_type == :dhcp
              guest_network.configure_dhcp_interface(
                interface[:index],
                interface[:net_connection_id])
            else
              raise WindowsError, "#{network_type} network type is not supported, try static or dhcp"
            end
          end
          guest_network.set_all_networks_to_work() if machine.config.windows.set_work_network
        end
        
        #{1=>{:name=>"Local Area Connection", :mac_address=>"0800275FAC5B", :interface_index=>"11", :index=>"7"}}
        def self.create_vm_interface_map(machine, guest_network)
          vm_interface_map = {}
          driver_mac_address = machine.provider.driver.read_mac_addresses.invert
          @@logger.debug("mac addresses: #{driver_mac_address.inspect}")
          guest_network.network_adapters().each do |nic|
            @@logger.debug("nic: #{nic.inspect}")
            naked_mac = nic[:mac_address].gsub(':','')
            if driver_mac_address[naked_mac]
              vm_interface_map[driver_mac_address[naked_mac]] = {
                :name => nic[:net_connection_id],
                :mac_address => naked_mac,
                :interface_index => nic[:interface_index],
                :index => nic[:index] }
            end
          end
          @@logger.debug("vm_interface_map: #{vm_interface_map.inspect}")
          vm_interface_map
        end

      end
    end
  end
end
