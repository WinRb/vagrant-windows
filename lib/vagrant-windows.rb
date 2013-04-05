require "pathname"
require "vagrant-windows/plugin"

module VagrantWindows
  # This returns the path to the source of this plugin.
  #
  # @return [Pathname]
  def self.source_root
    @source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
  end
end