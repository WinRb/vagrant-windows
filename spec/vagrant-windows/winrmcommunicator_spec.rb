require 'spec_helper'

describe VagrantWindows::Communication::WinRMCommunicator, :integration => true do
  
  before(:all) do
    # This test requires you already have a running Windows Server 2008 R2 Vagrant VM
    # Not ideal, but you have to start somewhere
    @shell = VagrantWindows::Communication::WinRMShell.new("localhost", "vagrant", "vagrant")
    @communicator = VagrantWindows::Communication::WinRMCommunicator.new({})
    @communicator.set_winrmshell(@shell)
  end
  
  describe "execute" do
    it "should return 1 when error_check is false" do
      expect(@communicator.execute("exit 1", { :error_check => false })).to eq(1)
    end
    
    it "should raise WinRMExecutionError when error_check is true" do
      expect { @communicator.execute("exit 1") }.to raise_error(VagrantWindows::Errors::WinRMExecutionError)
    end
    
    it "should raise specified error type when specified and error_check is true" do
      opts = { :error_class => VagrantWindows::Errors::WinRMInvalidShell }
      expect { @communicator.execute("exit 1", opts) }.to raise_error(VagrantWindows::Errors::WinRMInvalidShell)
    end
  end

end
