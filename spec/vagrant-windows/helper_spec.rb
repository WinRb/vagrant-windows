require 'spec_helper'
require 'mocha/api'

describe VagrantWindows::Helper , :unit => true do
  
  class DummyHelper
    include VagrantWindows::Helper
  end
  
  before(:all) do
    @dummy = DummyHelper.new
  end

  describe "win_friendly_path" do
    it "should replace slashes with backslashes"  do
      @dummy.win_friendly_path('c:/tmp/dir').should eq('c:\\tmp\\dir')
    end
    
    it "should prepend c: drive if not drive specified" do
      @dummy.win_friendly_path('/tmp/dir').should eq('c:\\tmp\\dir')
    end
    
    it "should return nil if no path specified" do
      @dummy.win_friendly_path(nil).should be_nil
    end
  end
  
  describe "win_friendly_share_id" do
    it "should use share id if present" do
      @dummy.win_friendly_share_id('sharename').should eq('sharename')
    end
    
    it "should use last folder name in guest_path" do
      @dummy.win_friendly_share_id('/tmp/folder/sharename').should eq('tmp_folder_sharename')
    end

  end
  
  describe "is_vmware" do
    it "should be true for vmware_fusion" do
      machine = stub(:provider_name => :vmware_fusion)
      expect(@dummy.is_vmware(machine)).to be_true
    end
    
    it "should be true for vmware_workstation" do
      machine = stub(:provider_name => :vmware_workstation)
      expect(@dummy.is_vmware(machine)).to be_true
    end
    
    it "should be false for virtual_box" do
      machine = stub(:provider_name => :virtual_box)
      expect(@dummy.is_vmware(machine)).to be_false
    end

  end

end
