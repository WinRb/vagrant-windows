require 'spec_helper'

describe VagrantWindows::Communication::WinRMCommunicator, :integration => true do
  
  before(:all) do
    # This test requires you already have a running Windows Server 2008 R2 Vagrant VM
    # Not ideal, but you have to start somewhere
    @communicator = VagrantWindows::Communication::WinRMCommunicator.new({})
    @communicator.winrmshell = VagrantWindows::Communication::WinRMShell.new("localhost", "vagrant", "vagrant")
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
  
  describe "upload" do
    it "should upload the file and overwrite it if it exists" do
      test_file = Tempfile.new("uploadtest")
      IO.write(test_file, "hello world")
      @communicator.upload(test_file, "c:\\vagrantuploadtest.txt")
      
      # ensure we can overwrite
      IO.write(test_file, "goodbye cruel world")
      @communicator.upload(test_file, "c:\\vagrantuploadtest.txt")
      
      # get the uploaded file's contents to ensure it uploaded properly
      uploaded_file_content = ''
      @communicator.execute("cat c:\\vagrantuploadtest.txt", {}) do |type, line|
        uploaded_file_content = uploaded_file_content + line
      end
      
      expect(uploaded_file_content.chomp).to eq("goodbye cruel world")
    end
  end

end
