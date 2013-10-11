require 'spec_helper'

describe VagrantWindows::Communication::WinRMFinder, :unit => true do

  before(:each) do
    @machine = stub()
    @winrmfinder = VagrantWindows::Communication::WinRMFinder.new(@machine)
  end

  describe 'winrm_host_address' do
    it 'should raise WinRMNotReady exception when ssh_info is nil' do
      @machine.stubs(:ssh_info).returns(nil)
      expect { @winrmfinder.winrm_host_address() }.to raise_error(VagrantWindows::Errors::WinRMNotReady)
    end
    
    it 'should return ssh_info host if config host has no value' do
      # setup the winrm config to return nil for the host (i.e. the default)
      winrm_config = VagrantWindows::Config::WinRM.new()
      winrm_config.finalize!()
      machine_config = stub(:winrm => winrm_config)
      @machine.stubs(:config).returns(machine_config)
      
      # setup the machine ssh_info to return a 10.0.0.1
      @machine.stubs(:ssh_info).returns({ :host => '10.0.0.1' })
      
      expect(@winrmfinder.winrm_host_address()).to eq('10.0.0.1')
    end
    
    it 'should return host config if set (issue 104)' do
      # setup the winrm config to return nil for the host (i.e. the default)
      winrm_config = VagrantWindows::Config::WinRM.new()
      winrm_config.host = '10.0.0.1'
      winrm_config.finalize!()
      machine_config = stub(:winrm => winrm_config)
      @machine.stubs(:config).returns(machine_config)
      
      # setup the machine ssh_info to return a 10.0.0.1
      @machine.stubs(:ssh_info).returns({ :host => '127.0.0.1' })
      
      expect(@winrmfinder.winrm_host_address()).to eq('10.0.0.1')
    end
  end

end
