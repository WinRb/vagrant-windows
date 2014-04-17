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

  describe 'chef_arguments' do
    it 'should include paths to client.rb and dna.json' do
      expected = '-c c:\tmp\vagrant-chef-1\client.rb -j c:\tmp\vagrant-chef-1\dna.json'
      @chef_cmd_builder.chef_arguments().should eql expected
    end

    it 'should include Chef arguments if specified' do
      @chef_config.stubs(:arguments).returns('-l DEBUG')
      expected = '-c c:\tmp\vagrant-chef-1\client.rb -j c:\tmp\vagrant-chef-1\dna.json -l DEBUG'
      @chef_cmd_builder.chef_arguments().should eql expected
    end
  end

  describe 'run chef command' do
    it "should include chef-client cmd line" do
      expect(@chef_cmd_builder.run_chef_command()).to include(
        'chef-client -c c:\\tmp\\vagrant-chef-1\\client.rb -j c:\\tmp\\vagrant-chef-1\\dna.json')
    end
  end

end
