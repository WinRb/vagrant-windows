module Vagrant
  module Guest
    # A general Vagrant system implementation for "windows".
    #
    # Contributed by Chris McClimans <chris@hippiehacker.org>
    class Windows2008R2 < Windows
    end
  end
end

Vagrant.guests.register(:windows2008r2)  { Vagrant::Guest::Windows2008R2 }
