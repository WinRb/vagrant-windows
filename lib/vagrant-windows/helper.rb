module VagrantWindows
  module Helper
    extend self
    
    # Makes a path Windows guest friendly.
    # Turns '/vagrant' into 'c:\vagrant'
    #
    # @return [String]
    def win_friendly_path(path)
      if path
        new_path = path.gsub('/', '\\')
        new_path = "c:#{new_path}" if new_path =~ /^\\/
      end
      new_path
    end

    # Makes Vagrant share names Windows guest friendly.
    # Turns '/vagrant' into 'vagrant' or turns ''/a/b/c/d/e' into 'a_b_c_d_e'
    #
    # @return [String]
    def win_friendly_share_id(shared_folder_name)
      return shared_folder_name.gsub(/[\/\/]/,'_').sub(/^_/, '')
    end
    
    # Checks to see if the specified machine is using VMWare Fusion or Workstation.
    #
    # @return [Boolean]
    def is_vmware(machine)
      machine.provider_name.to_s().start_with?('vmware')
    end
    
  end
end