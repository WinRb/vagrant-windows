require "pathname"

module VagrantWindows
  
  def self.vagrant_lib_root
    # example match: /Applications/Vagrant/embedded/gems/gems/vagrant-1.1.2/lib
    @vagrant_lib_root ||= $LOAD_PATH.select { |p| p =~ /\/vagrant-[1-9].[0-9].[0-9]\/lib/ }.first
  end
  
  def self.vagrant_root
    @vagrant_root ||= Pathname.new(File.expand_path("../", vagrant_lib_root))
  end
  
  def self.vagrant_windows_root
    @vagrant_windows_root ||= Pathname.new(File.expand_path("../../", __FILE__))
  end
  
end

require "vagrant-windows/plugin"
