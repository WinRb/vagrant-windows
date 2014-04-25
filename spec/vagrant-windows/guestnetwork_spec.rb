require 'spec_helper'

describe VagrantWindows::Communication::GuestNetwork , :integration => true do
  
  before(:each) do
    port = (ENV['WINRM_PORT'] || 5985).to_i

    @machine = stub()
    @shell = VagrantWindows::Communication::WinRMShell.new(
      "127.0.0.1", "vagrant", "vagrant", { port: port })

    @communicator = VagrantWindows::Communication::WinRMCommunicator.new(@machine)
    @communicator.winrmshell = @shell
    @guestnetwork = VagrantWindows::Communication::GuestNetwork.new(@communicator)
  end
  
  describe "wsman_version" do
    it "network_adapters" do
      nics = @guestnetwork.network_adapters()
      #puts nics.pretty_inspect()

      expect(nics.count).to be >= 1
      nic = nics[0]

      expect(nic.has_key?(:mac_address)).to be_true
      expect(nic.has_key?(:net_connection_id)).to be_true
      expect(nic.has_key?(:interface_index)).to be_true
      expect(nic.has_key?(:index)).to be_true
      
      expect(nic[:mac_address]).to match(/^([0-9A-F]{2}[:]){5}([0-9A-F]{2})$/)
      Integer(nic[:interface_index])
      Integer(nic[:index])
    end
    
    it "should configure DHCP for adapter" do
      nics = @guestnetwork.network_adapters()
      @guestnetwork.configure_dhcp_interface(nics[0][:index], nics[0][:net_connection_id])
      expect(@guestnetwork.is_dhcp_enabled(nics[0][:index])).to be_true
    end
    
    it "should configure static IP for adapter" do
      nics = @guestnetwork.network_adapters()
      @guestnetwork.configure_static_interface(
        nics[1][:index],
        nics[1][:net_connection_id],
        "192.168.0.121",
        "255.255.255.0")
        
      expect(@guestnetwork.is_dhcp_enabled(nics[1][:index])).to be_false
      
      # ensure the right IP was set by looking through all the output of ipconfig
      ipconfig_out = ''
      @shell.powershell('ipconfig /all') do |_, line|
        ipconfig_out = ipconfig_out + "#{line}"
      end
      expect(ipconfig_out).to include('192.168.0.121')
    end
    
    it "should configure all networks to work mode" do
      @guestnetwork.set_all_networks_to_work()
    end
  end

end
