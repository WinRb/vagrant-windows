require 'timeout'
require 'log4r'
require_relative '../errors'
require_relative '../windows_machine'
require_relative 'winrmshell'

module VagrantWindows
  module Communication
    # Provides communication channel for Vagrant commands via WinRM.
    class WinRMCommunicator < Vagrant.plugin("2", :communicator)

      attr_reader :logger
      attr_reader :winrm_finder
      attr_reader :windows_machine
      
      def self.match?(machine)
        VagrantWindows::WindowsMachine.is_windows?(machine)
      end

      def initialize(machine)
        @windows_machine = VagrantWindows::WindowsMachine.new(machine)
        @winrm_finder = WinRMFinder.new(@windows_machine)
        @logger = Log4r::Logger.new("vagrant_windows::communication::winrmcommunicator")
        @logger.debug("initializing WinRMCommunicator")
      end

      def ready?
        @logger.debug("Checking whether WinRM is ready...")

        Timeout.timeout(@windows_machine.winrm_config.timeout) do
          winrmshell.powershell("hostname")
        end

        @logger.info("WinRM is ready!")
        return true
        
      rescue Vagrant::Errors::VagrantError => e
        # We catch a `VagrantError` which would signal that something went
        # wrong expectedly in the `connect`, which means we didn't connect.
        @logger.info("WinRM not up: #{e.inspect}")
        return false
      end
      
      def execute(command, opts={}, &block)
        if opts[:shell].eql? :cmd
          winrmshell.cmd(command, &block)[:exitcode]
        else
          command = VagrantWindows.load_script("command_alias.ps1") << "\r\n" << command
          winrmshell.powershell(command, &block)[:exitcode]
        end
      end
      alias_method :sudo, :execute
      
      def test(command, opts=nil)
        # HACK: to speed up Vagrant 1.2 OS detection, skip checking for *nix OS
        return false unless (command =~ /^uname|^cat \/etc|^cat \/proc|grep 'Fedora/).nil?
        execute(command) == 0
      end

      def upload(from, to)
        @logger.debug("Uploading: #{from} to #{to}")
        file = "winrm-upload-#{rand()}"
        file_name = (winrmshell.cmd("echo %TEMP%\\#{file}"))[:data][0][:stdout].chomp
        winrmshell.powershell <<-EOH
          if(Test-Path #{to})
          {
            rm #{to}
          }
        EOH
        Base64.encode64(IO.binread(from)).gsub("\n",'').chars.to_a.each_slice(8000-file_name.size) do |chunk|
          out = winrmshell.cmd("echo #{chunk.join} >> \"#{file_name}\"")
        end
        winrmshell.powershell("mkdir $([System.IO.Path]::GetDirectoryName(\"#{to}\"))")
        winrmshell.powershell <<-EOH
          $base64_string = Get-Content \"#{file_name}\"
          $bytes  = [System.Convert]::FromBase64String($base64_string) 
          $new_file = [System.IO.Path]::GetFullPath(\"#{to}\")
          [System.IO.File]::WriteAllBytes($new_file,$bytes)
        EOH
      end
      
      def download(from, to=nil)
        @logger.warn("Downloading: #{from} to #{to} not supported on Windows guests")
      end
      
      def set_winrmshell(winrmshell)
        @winrmshell = winrmshell
      end
      
      def winrmshell()
        @winrmshell ||= new_winrmshell
      end
      
      
      protected
      
      def new_winrmshell()
        WinRMShell.new(
          @winrm_finder.find_winrm_host_address(),
          @windows_machine.winrm_config.username,
          @windows_machine.winrm_config.password,
          {
            :port => @winrm_finder.find_winrm_host_port(),
            :timeout_in_seconds => @windows_machine.winrm_config.timeout,
            :max_tries => @windows_machine.winrm_config.max_tries
          })
      end
      
    end #WinRM class
  end
end
