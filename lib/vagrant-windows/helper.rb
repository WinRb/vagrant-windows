module VagrantWindows
  module Helper
    extend self
    
    def win_friendly_path(path)
      if path
        new_path = path.gsub('/', '\\')
        new_path = "c:#{new_path}" if new_path =~ /^\\/
      end
      new_path
    end

    # turns '/vagrant' into 'vagrant' or turns ''/a/b/c/d/e' into 'a_b_c_d_e'
    def win_friendly_share_id(shared_folder_name)
      return shared_folder_name.gsub(/[\/\/]/,'_').sub(/^_/, '')
    end
    
  end
end