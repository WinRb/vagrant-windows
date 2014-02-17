require 'spec_helper'
require 'mocha/api'
require 'vagrant-windows/communication/linux_command_filter'

describe VagrantWindows::Communication::LinuxCommandFilter, :unit => true do
  
  before(:each) do
    @filter = VagrantWindows::Communication::LinuxCommandFilter.new()
  end

  describe "filter" do
    it "should return empty string for chmod"  do
      expect(@filter.filter('chmod -R 600 /var/cfengine/ppkeys')).to eq('')
    end

    it "should return empty string for chown"  do
      expect(@filter.filter('chown -R admin /tmp/dir')).to eq('')
    end

    it "should convert linux which command to PS equivalent"  do
      expected = <<-EOH
          $command = [Array](Get-Command ruby -errorAction SilentlyContinue)
          if ($null -eq $command) { exit 1 }
          write-host $command[0].Definition
          exit 0
        EOH
      expect(@filter.filter('which ruby')).to eq(expected)
    end

    it "should convert linux rm command to PS equivalent"  do
      expect(@filter.filter('rm /tmp/dir')).to eq("rm '/tmp/dir' -recurse -force")
    end

    it "should convert linux rm recursive command to PS equivalent"  do
      expect(@filter.filter('rm -Rf /tmp/dir')).to eq("rm '/tmp/dir' -recurse -force")
    end

    it "should convert linux test -d command to PS equivalent"  do
      expect(@filter.filter('test -d /tmp/dir')).to eq("if (Test-Path '/tmp/dir') { exit 0 } exit 1")
    end

    it "should convert linux test -x command to PS equivalent"  do
      expect(@filter.filter('test -x /tmp/ruby.exe')).to eq("if (Test-Path '/tmp/ruby.exe') { exit 0 } exit 1")
    end

    it "should convert linux test -f command to PS equivalent"  do
      expect(@filter.filter('test -f /tmp/file.txt')).to eq("if (Test-Path '/tmp/file.txt') { exit 0 } exit 1")
    end

   it "should convert linux test -L command to PS equivalent"  do
      expect(@filter.filter('test -L /tmp/link')).to eq("if (Test-Path '/tmp/link') { exit 0 } exit 1")
    end

  end
    
end
