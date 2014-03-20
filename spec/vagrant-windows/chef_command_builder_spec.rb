require 'spec_helper'

describe VagrantWindows::Provisioners::ChefCommandBuilder, :unit => true do

  before(:each) do
    @winrm_config = stub()
    @winrm_config.stubs(:username).returns('vagrant')
    @winrm_config.stubs(:password).returns('secret')

    @windows_machine = stub()
    @windows_machine.stubs(:winrm_config).returns(@winrm_config)

    @chef_config = stub()
    @chef_config.stubs(:provisioning_path).returns('/tmp/vagrant-chef-1')
    @chef_config.stubs(:arguments).returns(nil)
    @chef_config.stubs(:binary_env).returns(nil)
    @chef_config.stubs(:binary_path).returns(nil)

    @chef_cmd_builder = VagrantWindows::Provisioners::ChefCommandBuilder.new(
      @windows_machine, @chef_config, :client)
  end

  describe 'initialize' do
    it 'should raise when chef type is not client or solo' do
      expect { VagrantWindows::Provisioners::ChefCommandBuilder.new(@windows_machine, @chef_config, :zero) }.to raise_error
    end
  end

  describe 'provisioning_path' do
    it 'should be windows friendly' do
      @chef_cmd_builder.provisioning_path('script.ps1').should eql 'c:\tmp\vagrant-chef-1\script.ps1'
    end
  end

  describe 'create_chef_arguments' do
    it 'should include paths to client.rb and dna.json' do
      expected = '-c c:\tmp\vagrant-chef-1\client.rb -j c:\tmp\vagrant-chef-1\dna.json'
      @chef_cmd_builder.create_chef_arguments().should eql expected
    end

    it 'should include Chef arguments if specified' do
      @chef_config.stubs(:arguments).returns('-l DEBUG')
      expected = '-c c:\tmp\vagrant-chef-1\client.rb -j c:\tmp\vagrant-chef-1\dna.json -l DEBUG'
      @chef_cmd_builder.create_chef_arguments().should eql expected
    end
  end

  describe 'create_chef_options' do
    it "should include winrm username and password" do
      options = @chef_cmd_builder.create_chef_options()
      options[:user].should eql 'vagrant'
      options[:pass].should eql 'secret'
    end

    it 'should include paths to scripts' do
      options = @chef_cmd_builder.create_chef_options()
      options[:chef_task_xml].should eql 'c:\tmp\vagrant-chef-1\cheftask.xml'
      options[:chef_task_ps1].should eql 'c:\tmp\vagrant-chef-1\cheftask.ps1'
      options[:chef_task_run_ps1].should eql 'c:\tmp\vagrant-chef-1\cheftaskrun.ps1'
    end

    it 'should include paths to process flow files' do
      options = @chef_cmd_builder.create_chef_options()
      options[:chef_task_running].should eql 'c:\tmp\vagrant-chef-1\cheftask.running'
      options[:chef_task_exitcode].should eql 'c:\tmp\vagrant-chef-1\cheftask.exitcode'
    end

    it 'should include paths to logs' do
      options = @chef_cmd_builder.create_chef_options()
      options[:chef_stdout_log].should eql 'c:\tmp\vagrant-chef-1\chef-client.log'
      options[:chef_stderr_log].should eql 'c:\tmp\vagrant-chef-1\chef-client.err.log'
    end

    it 'should include path to chef binary' do
      options = @chef_cmd_builder.create_chef_options()
      options[:chef_binary_path].should eql 'chef-client'
    end

    it 'should include full path to chef binary when binary_path is set' do
      @chef_config.stubs(:binary_path).returns('c:/opscode/chef/bin')
      options = @chef_cmd_builder.create_chef_options()
      options[:chef_binary_path].should eql 'c:\opscode\chef\bin\chef-client'
    end

  end

  describe 'prepare_for_chef_run' do
    it 'should upload cheftask scripts' do
      winrmshell = double()
      @windows_machine.stubs(:winrmshell).returns(winrmshell)

      winrmshell.should_receive(:upload).with(anything(), 'c:\tmp\vagrant-chef-1\cheftaskrun.ps1')
      winrmshell.should_receive(:upload).with(anything(), 'c:\tmp\vagrant-chef-1\cheftask.xml')
      winrmshell.should_receive(:upload).with(anything(), 'c:\tmp\vagrant-chef-1\cheftask.ps1')

      @chef_cmd_builder.prepare_for_chef_run()
    end

  end

end
