require "pathname"

module VagrantWindows
  
  def self.vagrant_windows_root
    @vagrant_windows_root ||= Pathname.new(File.expand_path("../../", __FILE__))
  end
  
  def self.load_script(script_file_name)
    File.read(expand_script_path(script_file_name))
  end
  
  def self.load_script_template(script_file_name, options)
    Vagrant::Util::TemplateRenderer.render(expand_script_path(script_file_name), options)
  end
  
  def self.expand_script_path(script_file_name)
    File.expand_path("lib/vagrant-windows/scripts/#{script_file_name}", VagrantWindows.vagrant_windows_root)
  end

  
end

require "vagrant-windows/plugin"
