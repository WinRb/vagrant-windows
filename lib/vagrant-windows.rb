require "vagrant-windows/plugin"

module VagrantPlugins
  module Windows
    lib_path = Pathname.new(File.expand_path("../vagrant-windows", __FILE__))
    
    autoload :Errors, lib_path.join("errors")
    autoload :WinRM, lib_path.join("winrm")
  end
end
