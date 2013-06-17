module VagrantWindows
  module Helper
    
    def win_friendly_path(path)
      if path
        new_path = path.gsub('/', '\\')
        new_path = "c:#{new_path}" if new_path =~ /^\\/
      end
      new_path
    end
    
  end
end