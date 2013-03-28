module Vagrant
  class Machine
    
    ssh_communicate = instance_method(:communicate)
    
    define_method(:communicate) do
      if @guest.class.eql? Vagrant::Guest::Windows
        @communicator ||= Communication::WinRM.new(self)
      else
        @communicator ||= ssh_communicate.bind(self).()
      end
      @communicator
    end
    
    def winrm
      @winrm ||= WinRM.new(self)
    end

  end
end