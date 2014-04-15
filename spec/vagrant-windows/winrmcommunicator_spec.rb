require 'spec_helper'

describe VagrantWindows::Communication::WinRMCommunicator, :integration => true do
  
  before(:all) do
    @communicator = VagrantWindows::Communication::WinRMCommunicator.new({})
    port = (ENV['WINRM_PORT'] || 5985).to_i
    @communicator.winrmshell = VagrantWindows::Communication::WinRMShell.new(
      "127.0.0.1", "vagrant", "vagrant", { port: port })
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
