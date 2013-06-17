module VagrantWindows
  module Helper
    
    def win_friendly_path(path)
      if path
        new_path = path.gsub('/', '\\')
        new_path = "c:#{new_path}" if new_path =~ /^\\/
      end
      new_path
    end
    
    # Creates a Windows friendly share name to be used by the
    # vagrant vm config monkey patch
    def win_friendly_share_id(options)
      id = options[:id] || options[:guestpath]
      if id =~ /\//
        parts = id.split(/\//)
        id = parts[parts.length - 1]
      end
      id
    end
    
  end
end