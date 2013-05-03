module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      class Version_4_2
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
    end
  end
end