module Vagrant
  module Guest
    # Windows Server 2003-specific overrides would go here.
    class Windows2003 < Windows
    end
  end
end

Vagrant.guests.register(:windows2003)  { Vagrant::Guest::Windows2003 }
