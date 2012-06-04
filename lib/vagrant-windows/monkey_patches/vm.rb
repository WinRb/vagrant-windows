module Vagrant
  class VM
    def winrm
      @winrm ||= WinRM.new(self)
    end

    def channel
      if @guest.class.eql? Vagrant::Guest::Windows
        @channel ||= Communication::WinRM.new(self)
      else
        @channel ||= Communication::SSH.new(self)
      end
      @channel 
    end
  end
end