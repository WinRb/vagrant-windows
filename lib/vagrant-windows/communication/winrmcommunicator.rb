require 'timeout'
require 'log4r'
require_relative '../errors'
require_relative 'winrmshell'
require_relative 'winrmfinder'

module VagrantWindows
  module Communication
    # Provides communication with the VM via WinRM.
    class WinRMCommunicator < Vagrant.plugin("2", :communicator)

      attr_reader :logger
      attr_reader :machine
      attr_reader :winrm_finder
      
      def self.match?(machine)
        machine.config.vm.guest.eql? :windows
      end

      def initialize(machine)
        @machine = machine
        @logger = Log4r::Logger.new("vagrant_windows::communication::winrmcommunicator")
        @logger.debug("initializing WinRMCommunicator")
        @winrm_finder = WinRMFinder.new(machine)
      end

      def ready?
        logger.debug("Checking whether WinRM is ready...")

        Timeout.timeout(@machine.config.winrm.timeout) do
          session.powershell("hostname")
        end

        logger.info("WinRM is ready!")
        return true
        
      rescue Vagrant::Errors::VagrantError => e
        # We catch a `VagrantError` which would signal that something went
        # wrong expectedly in the `connect`, which means we didn't connect.
        @logger.info("WinRM not up: #{e.inspect}")
        return false
      end
      
      def execute(command, opts={}, &block)
        if opts[:shell].eql? :cmd
          session.cmd(command, &block)[:exitcode]
        else
          command = VagrantWindows.load_script("command_alias.ps1") << "\r\n" << command
          session.powershell(command, &block)[:exitcode]
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
        file_name = (session.cmd("echo %TEMP%\\#{file}"))[:data][0][:stdout].chomp
        session.powershell <<-EOH
          if(Test-Path #{to})
          {
            rm #{to}
          }
        EOH
        Base64.encode64(IO.binread(from)).gsub("\n",'').chars.to_a.each_slice(8000-file_name.size) do |chunk|
          out = session.cmd("echo #{chunk.join} >> \"#{file_name}\"")
        end
        session.powershell("mkdir $([System.IO.Path]::GetDirectoryName(\"#{to}\"))")
        session.powershell <<-EOH
          $base64_string = Get-Content \"#{file_name}\"
          $bytes  = [System.Convert]::FromBase64String($base64_string) 
          $new_file = [System.IO.Path]::GetFullPath(\"#{to}\")
          [System.IO.File]::WriteAllBytes($new_file,$bytes)
        EOH
      end
      
      def download(from, to=nil)
        @logger.warn("Downloading: #{from} to #{to} not supported on Windows guests")
      end
      
      # Runs a remote WQL query against the VM
      #
      # Note: This is not part of the standard Vagrant communicator interface, but
      # guest capabilities may need to use this.
      def wql(query)
        session.wql(query)
      end
      
      def set_winrmshell(winrmshell)
        @session = winrmshell
      end
      
      def session
        @session ||= new_session
      end
      alias_method :winrmshell, :session
      
      
      protected
      
      def new_session
        WinRMShell.new(
          @winrm_finder.winrm_host_address(),
          @machine.config.winrm.username,
          @machine.config.winrm.password,
          {
            :port => @winrm_finder.winrm_host_port(),
            :timeout_in_seconds => @machine.config.winrm.timeout,
            :max_tries => @machine.config.winrm.max_tries
          })
      end
      
    end #WinRM class
  end
end
