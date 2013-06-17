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
      options = {}
      options[:id] = 'sharename'
      @dummy.win_friendly_share_id(options).should eq('sharename')
    end
    
    it "should use guest_path if share id missing" do
      options = {}
      options[:guestpath] = 'guestpath'
      @dummy.win_friendly_share_id(options).should eq('guestpath')

    end
    
    it "should use last folder name in guest_path" do
      options = {}
      options[:guestpath] = '/tmp/folder/sharename'
      @dummy.win_friendly_share_id(options).should eq('sharename')
    end
    
    it "should use last folder name in guest_path with trailing slash" do
      options = {}
      options[:guestpath] = '/tmp/folder/sharename/'
      @dummy.win_friendly_share_id(options).should eq('sharename')
    end
  end

end
