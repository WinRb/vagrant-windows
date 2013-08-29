require "vagrant-windows/communication/guestnetwork"
require "vagrant-windows/communication/winrmshell"

describe VagrantWindows::Communication::GuestNetwork do
  
  before(:all) do
    # This test requires you already have a running Windows Server 2008 R2 Vagrant VM
    # Not ideal, but you have to start somewhere
    @shell = VagrantWindows::Communication::WinRMShell.new("localhost", "vagrant", "vagrant")
    @guestnetwork = VagrantWindows::Communication::GuestNetwork.new(@shell)
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
      @guestnetwork.configure_static_interface(nics[1][:index], nics[1][:net_connection_id], "192.168.0.100", "255.255.255.0")
      expect(@guestnetwork.is_dhcp_enabled(nics[1][:index])).to be_false
    end
    
    it "should configure all networks to work mode" do
      @guestnetwork.set_all_networks_to_work()
    end
  end

end
