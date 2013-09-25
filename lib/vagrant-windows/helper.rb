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
    # Turns '/vagrant' into 'vagrant', '/a/b/c/d/e' into 'a_b_c_d_e', and 'v:' or 'v:/' into 'v'
    #
    # @return [String]
    def win_friendly_share_id(shared_folder_name)
      # replace /, \, and all other reserved windows pathname characters with _; then, cleanup _ groups, and any leading or trailing _'s
      # URLref: [MSDN - Naming Files, Paths, and Namespaces] http://msdn.microsoft.com/en-us/library/windows/desktop/aa365247(v=vs.85).aspx @@ http://archive.is/w9ddA @@ http://webcitation.org/6JK50Gyil
      return shared_folder_name.gsub(/[\/\\<>:"|?*]/,'_').gsub(/__+/,'_').sub(/^_/,'').sub(/_$/,'')
    end
    
    # Checks to see if the specified machine is using VMWare Fusion or Workstation.
    #
    # @return [Boolean]
    def is_vmware(machine)
      machine.provider_name.to_s().start_with?('vmware')
    end
    
  end
end