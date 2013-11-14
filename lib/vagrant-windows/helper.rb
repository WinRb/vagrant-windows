module VagrantWindows
  module Helper
    extend self
    
    @@logger = Log4r::Logger.new("vagrant_windows::helper")
    
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
    
    # Check to see if the guest is rebooting, if its rebooting then wait until its ready
    #
    # @param [WindowsMachine] The windows machine instance
    # @param [Int] The time in seconds to wait between checks
    def wait_if_rebooting(windows_machine, wait_in_seconds=10)
      @@logger.info('Checking guest reboot status')
      while windows_machine.is_rebooting? 
        @@logger.debug('Guest is rebooting, waiting 10 seconds...')
        sleep(wait_in_seconds)
      end
    end

  end
end