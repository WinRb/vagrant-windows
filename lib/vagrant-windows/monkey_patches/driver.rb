#require 'plugins/providers/virtualbox/driver/base'
#require 'plugins/providers/virtualbox/driver/meta'

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      
      class Version_4_2 < VagrantPlugins::ProviderVirtualBox::Driver::Base
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
          @logger.info("macs: #{macs.inspect}")
          macs
        end
      end

    #class VirtualBox < VirtualBoxBase
    #  def_delegator :@driver, :read_mac_addresses
    #end
    
    end
  end
end