require "vagrant-windows/helper"

describe VagrantWindows::Helper do
  
  class DummyHelper
    include VagrantWindows::Helper
  end
  
  before(:all) do
    @dummy = DummyHelper.new
  end

  describe "win_friendly_path" do
    it "should replace slashes with backslashes" do
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

end
