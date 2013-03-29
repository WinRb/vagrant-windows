module Vagrant
  class Machine
    
    #ssh_communicate = instance_method(:communicate)
    
    # This patch is needed until Vagrant supports a configurable communication channel
    #define_method(:communicate) do
    #  if @guest.class.eql? VagrantPlugins::Windows::Guest
    #    @communicator ||= Communication::WinRMCommunicator.new(self)
    #  else
    #    @communicator ||= ssh_communicate.bind(self).()
    #  end
    #  @communicator
    #end
    
    def communicate
      @communicator ||= Communication::WinRMCommunicator.new(self)
    end
    
    def winrm
      @winrm ||= WinRM.new(self)
    end

  end
end