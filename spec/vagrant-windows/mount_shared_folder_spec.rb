require 'spec_helper'
require 'mocha/api'
require 'vagrant-windows/guest/cap/mount_shared_folder'

describe VagrantWindows::Guest::Cap::MountSharedFolder, :unit => true do
  
  before(:each) do
    @communicator = mock()
    @machine = stub(:communicate => @communicator)
  end

  describe "mount_virtualbox_shared_folder" do
    it "should run script with vbox paths"  do
      @communicator.expects(:execute).with do |script, options|
        expect(script).to include("$VP = \"\\\\vboxsrv\\vagrant\"")
      end      

      VagrantWindows::Guest::Cap::MountSharedFolder.mount_virtualbox_shared_folder(
        @machine, "vagrant", "/tmp/vagrant", {})
    end
  end
    
  describe "mount_vmware_shared_folder" do
    it "should run script with vmware paths"  do
      @communicator.expects(:execute).with do |script, options|
        expect(script).to include("$VP = \"\\\\vmware-host\\Shared Folders\\vagrant\"")
      end
      
      VagrantWindows::Guest::Cap::MountSharedFolder.mount_vmware_shared_folder(
        @machine, "vagrant", "/tmp/vagrant", {})
    end
  end
  
end
