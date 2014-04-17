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
      @communicator.upload(test_file, "c:/tmp/winrm-test/vagrantuploadtest.txt")
      
      # ensure we can overwrite
      IO.write(test_file, "goodbye cruel world")
      @communicator.upload(test_file, "c:/tmp/winrm-test/vagrantuploadtest.txt")
      
      # get the uploaded file's contents to ensure it uploaded properly
      uploaded_file_content = ''
      @communicator.execute("cat c:/tmp/winrm-test/vagrantuploadtest.txt", {}) do |type, line|
        uploaded_file_content = uploaded_file_content + line
      end
      
      expect(uploaded_file_content.chomp).to eq("goodbye cruel world")
    end

    it "should recursively upload directories" do
      # create a some test data
      host_src_dir = Dir.mktmpdir("winrm_comm")

      begin
        IO.write(File.join(host_src_dir, 'root.txt'), "root\n")

        subdir2 = File.join(host_src_dir, '/subdir1/subdir2')
        FileUtils.mkdir_p(subdir2)

        IO.write(File.join(subdir2, 'leaf1.txt'), "leaf1\n")
        IO.write(File.join(subdir2, 'leaf2.txt'), "leaf2\n")

        @communicator.upload(host_src_dir, '/tmp/winrm-test-upload') #c:\tmp\winrm-test-upload

        @communicator.execute <<-EOH
          function AssertExists($p) {
            if (!(Test-Path $p)) {
              exit 1
            }
          }

          AssertExists 'c:/tmp/winrm-test-upload/root.txt'
          AssertExists 'c:/tmp/winrm-test-upload/subdir1/subdir2/leaf2.txt'
          AssertExists 'c:/tmp/winrm-test-upload/subdir1/subdir2/leaf1.txt'
        EOH
      ensure
        FileUtils.remove_entry_secure host_src_dir
      end
    end
  end

  describe 'test' do
    it "should return true if directory exists" do
      @communicator.execute('mkdir -p /tmp/winrm-test/1')
      expect(@communicator.test('test -d /tmp/winrm-test/1')).to be_true
    end

    it "should return false if directory does not exist" do
      expect(@communicator.test('test -d /tmp/winrm-test/doesnotexit')).to be_false
    end

    it "should differentiate between directories and files" do
      @communicator.execute('mkdir -p /tmp/winrm-test/2')
      @communicator.execute('Add-Content /tmp/winrm-test/2/file.txt "The content"')
      expect(@communicator.test('test -d /tmp/winrm-test/2/file.txt')).to be_false
      expect(@communicator.test('test -f /tmp/winrm-test/2/file.txt')).to be_true
    end
  end

end
