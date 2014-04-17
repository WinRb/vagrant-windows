require 'spec_helper'
require 'vagrant-windows/communication/linux_command_filter'

describe VagrantWindows::Communication::LinuxCommandFilter, :unit => true do

  before(:each) do
    @cmd_filter = VagrantWindows::Communication::LinuxCommandFilter.new()
  end

  describe 'command filters' do
    it 'should initialize all command filters in command filters directory' do
      expect(@cmd_filter.command_filters()).not_to be_empty
    end
  end

  describe 'filter' do
    it 'should only apply applicable command filters' do
      expect(@cmd_filter.filter('uname -s stuff')).to eq('')
    end
  end

end
