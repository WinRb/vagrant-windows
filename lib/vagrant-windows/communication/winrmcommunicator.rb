require 'timeout'
require 'winrm'
require 'log4r'
require 'vagrant/util/ansi_escape_code_remover'
require 'vagrant/util/file_mode'
require 'vagrant/util/platform'
require 'vagrant/util/retryable'
require_relative '../errors'
require_relative 'winrmshell'

module VagrantWindows
  module Communication
    # Provides communication with the VM via WinRM.
    class WinRMCommunicator < Vagrant.plugin("2", :communicator)

      include Vagrant::Util::ANSIEscapeCodeRemover
      include Vagrant::Util::Retryable

      attr_reader :logger
      attr_reader :machine
      
      def self.match?(machine)
        machine.config.vm.guest.eql? :windows
      end

      def initialize(machine)
        @machine = machine
        @logger = Log4r::Logger.new("vagrant_windows::communication::winrmcommunicator")
        @logger.debug("initializing WinRMCommunicator")
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
        return false if not (command =~ /^uname|^cat \/etc|^cat \/proc|grep 'Fedora/).nil?
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
        
        # TODO: Is this correct? This was the old communicator upload return status code
        return 0
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
      
      
      protected
      
      def new_session
        WinRMShell.new(
          find_winrm_host(),
          @machine.config.winrm.username,
          @machine.config.winrm.password,
          {
            :port => find_winrm_host_port(),
            :timeout_in_seconds => @machine.config.winrm.timeout,
            :max_tries => @machine.config.winrm.max_tries
          })
      end

      def session
        @session ||= new_session
      end

      def find_winrm_host
        # Get the SSH info for the machine, raise an exception if the
        # provider is saying that SSH is not ready.
        ssh_info = @machine.ssh_info
        raise Vagrant::Errors::SSHNotReady if ssh_info.nil?
        @logger.info("Host: #{ssh_info[:host]}")
        return ssh_info[:host]
      end
      
      def find_winrm_host_port
        expected_guest_port = @machine.config.winrm.guest_port
        @logger.debug("Searching for WinRM port: #{expected_guest_port.inspect}")

        # Look for the forwarded port only by comparing the guest port
        begin
          @machine.provider.driver.read_forwarded_ports.each do |_, _, hostport, guestport|
            return hostport if guestport == expected_guest_port
          end
        rescue NoMethodError => e
          # VMWare provider doesn't support read_forwarded_ports
          @logger.debug(e.message)
        end
        
        # just use the configured port as-is
        @machine.config.winrm.port
      end
      
    end #WinRM class
  end
end
