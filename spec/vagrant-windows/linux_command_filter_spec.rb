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
    it 'should filter out uname commands' do
      expect(@cmd_filter.filter('uname -s stuff')).to eq('')
    end

    it 'should filter out which commands' do
      expect(@cmd_filter.filter('which ruby')).to include(
        '[Array](Get-Command ruby -errorAction SilentlyContinue)')
    end

    it 'should filter out test -d commands' do
      expect(@cmd_filter.filter('test -d /tmp/dir')).to eq(
        "if ((Test-Path '/tmp/dir') -and (get-item '/tmp/dir').PSIsContainer) { exit 0 } exit 1")
    end

    it 'should filter out test -f commands' do
      expect(@cmd_filter.filter('test -f /tmp/file.txt')).to eq(
        "if ((Test-Path '/tmp/file.txt') -and (!(get-item '/tmp/file.txt').PSIsContainer)) { exit 0 } exit 1")
    end

    it 'should filter out test -x commands' do
      expect(@cmd_filter.filter('test -x /tmp/file.txt')).to eq(
        "if ((Test-Path '/tmp/file.txt') -and (!(get-item '/tmp/file.txt').PSIsContainer)) { exit 0 } exit 1")
    end

    it 'should filter out other test commands' do
      expect(@cmd_filter.filter('test -L /tmp/file.txt')).to eq(
        "if (Test-Path '/tmp/file.txt') { exit 0 } exit 1")
    end

    it 'should filter out rm -Rf commands' do
      expect(@cmd_filter.filter('rm -Rf /some/dir')).to eq(
        "rm '/some/dir' -recurse -force")
    end

    it 'should filter out rm commands' do
      expect(@cmd_filter.filter('rm /some/dir')).to eq(
        "rm '/some/dir' -force")
    end

    it 'should filter out chown commands' do
      expect(@cmd_filter.filter("chown -R root '/tmp/dir'")).to eq('')
    end

    it 'should filter out chmod commands' do
      expect(@cmd_filter.filter("chmod 0600 ~/.ssh/authorized_keys")).to eq('')
    end

    it 'should filter out certain cat commands' do
      expect(@cmd_filter.filter("cat /etc/release | grep -i OmniOS")).to eq('')
    end

    it 'should not filter out other cat commands' do
      expect(@cmd_filter.filter("cat /tmp/somefile")).to eq('cat /tmp/somefile')
    end
  end

end
