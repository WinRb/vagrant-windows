module Vagrant
  class Machine
    
    ssh_communicate = instance_method(:communicate)
    
    # This patch is needed until Vagrant supports a configurable communication channel
    define_method(:communicate) do
      unless @communicator
        if @config.vm.guest.eql? :windows
          @logger.info("guest is #{@config.vm.guest}, using WinRM for communication channel")
          @communicator = ::VagrantWindows::Communication::WinRMCommunicator.new(self)
        else
          @logger.info("guest is #{@config.vm.guest}, using SSH for communication channel")
          @communicator = ssh_communicate.bind(self).()
        end
      end
      @communicator
    end
    
    def winrm
      @winrm ||= WinRM.new(self)
    end

  end
end