require 'vagrant/driver/virtualbox_base'
require 'vagrant/driver/virtualbox'


module Vagrant
  module Driver

    class VirtualBox_4_1 < VirtualBoxBase
      def read_mac_addresses
        macs = {}
        info = execute("showvminfo", @uuid, "--machinereadable", :retryable => true)
        info.split("\n").each do |line|
          if matcher = /^macaddress(\d+)="(.+?)"$/.match(line)
            adapter = matcher[1].to_i
            mac = matcher[2].to_s
            macs[adapter] = mac
          end
        end
        macs 
      end
    end

    class VirtualBox_4_0 < VirtualBoxBase
      def read_mac_addresses
        macs = {}
        info = execute("showvminfo", @uuid, "--machinereadable", :retryable => true)
        info.split("\n").each do |line|
          if matcher = /^macaddress(\d+)="(.+?)"$/.match(line)
            adapter = matcher[1].to_i
            mac = matcher[2].to_s
            macs[adapter] = mac
          end
        end
        macs 
      end
    end

    class VirtualBox < VirtualBoxBase
      def_delegator :@driver, :read_mac_addresses
    end
  end
end
