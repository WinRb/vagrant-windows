require "vagrant-windows/communication/guestnetwork"
require "vagrant-windows/communication/winrmshell"

describe VagrantWindows::Communication::WinRMCommunicator do
  
  before(:all) do
    # This test requires you already have a running Windows Server 2008 R2 Vagrant VM
    # Not ideal, but you have to start somewhere
    @shell = VagrantWindows::Communication::WinRMShell.new("localhost", "vagrant", "vagrant")
    @communicator = VagrantWindows::Communication::WinRMCommunicator.new({})
    @communicator.set_winrmshell(@shell)
  end
  
  describe "execute" do
    it "should return 1" do
      expect(@communicator.execute("exit 1")).to eq(1)
    end
    
    it "should return 1 with block" do
      exit_code = @communicator.sudo("exit 1", {}) do |type, line|
        puts line
      end
      expect(exit_code).to eq(1)
    end
  end

end
