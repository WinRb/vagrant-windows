require 'spec_helper'
require 'mocha/api'
require 'vagrant-windows/windows_machine'

describe VagrantWindows::WindowsMachine , :unit => true do
  
  describe "is_vmware?" do
    it "should be true for vmware_fusion" do
      machine = stub(:provider_name => :vmware_fusion)
      windows_machine = VagrantWindows::WindowsMachine.new(machine)
      expect(windows_machine.is_vmware?()).to be_true
    end
    
    it "should be true for vmware_workstation" do
      machine = stub(:provider_name => :vmware_workstation)
      windows_machine = VagrantWindows::WindowsMachine.new(machine)
      expect(windows_machine.is_vmware?()).to be_true
    end
    
    it "should be false for virtual_box" do
      machine = stub(:provider_name => :virtual_box)
      windows_machine = VagrantWindows::WindowsMachine.new(machine)
      expect(windows_machine.is_vmware?()).to be_false
    end
  end
  
  describe "is_virtualbox?" do
    it "should be true for virtualbox" do
      machine = stub(:provider_name => :virtualbox)
      windows_machine = VagrantWindows::WindowsMachine.new(machine)
      expect(windows_machine.is_virtualbox?()).to be_true
    end
    
    it "should be false for vmware_workstation" do
      machine = stub(:provider_name => :vmware_workstation)
      windows_machine = VagrantWindows::WindowsMachine.new(machine)
      expect(windows_machine.is_virtualbox?()).to be_false
    end
  end

  describe "is_parallels?" do
    it "should be true for parallels" do
      machine = stub(:provider_name => :parallels)
      windows_machine = VagrantWindows::WindowsMachine.new(machine)
      expect(windows_machine.is_parallels?()).to be_true
    end
    
    it "should be false for vmware_workstation" do
      machine = stub(:provider_name => :vmware_workstation)
      windows_machine = VagrantWindows::WindowsMachine.new(machine)
      expect(windows_machine.is_parallels?()).to be_false
    end
  end
  
  describe "is_windows?" do
    it "should return true when config vm guest is windows" do
      vm = stub(:guest => :windows)
      config = stub(:vm => vm)
      machine = stub(:config => config)
      expect(VagrantWindows::WindowsMachine.is_windows?(machine)).to be_true
    end

    it "instance should return true when config vm guest is windows" do
      vm = stub(:guest => :windows)
      config = stub(:vm => vm)
      machine = stub(:config => config)
      windows_machine = VagrantWindows::WindowsMachine.new(machine)
      expect(windows_machine.is_windows?()).to be_true
    end
    
    it "should return false when config vm guest is not windows" do
      vm = stub(:guest => :ubuntu)
      config = stub(:vm => vm)
      machine = stub(:config => config)
      expect(VagrantWindows::WindowsMachine.is_windows?(machine)).to be_false
    end

    it "instance should return false when config vm guest is not windows" do
      vm = stub(:guest => :fedora)
      config = stub(:vm => vm)
      machine = stub(:config => config)
      windows_machine = VagrantWindows::WindowsMachine.new(machine)
      expect(windows_machine.is_windows?()).to be_false
    end
  end
  
  describe "read_forwarded_ports" do
    it "should return empty array for vmware provider" do
      machine = stub(:provider_name => :vmware_fusion)
      windows_machine = VagrantWindows::WindowsMachine.new(machine)
      expect(windows_machine.read_forwarded_ports()).to eq([])
    end
  end

end
