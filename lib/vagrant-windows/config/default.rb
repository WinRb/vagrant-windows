Vagrant::Config.run do |config| 
  config.vm.forward_port 5985, 5985, :name => "winrm", :auto => true
end