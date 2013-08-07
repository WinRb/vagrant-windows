require 'timeout'
require 'winrm'
require 'log4r'
require 'vagrant/util/ansi_escape_code_remover'
require 'vagrant/util/file_mode'
require 'vagrant/util/platform'
require 'vagrant/util/retryable'
require_relative '../errors'

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
          execute("hostname") do |type, data|
            @logger.info("hostname: #{data}")
          end
        end

        # If we reached this point then we successfully connected
        logger.info("WinRM is ready!")
        true
        rescue Vagrant::Errors::VagrantError => e
        # We catch a `VagrantError` which would signal that something went
        # wrong expectedly in the `connect`, which means we didn't connect.
        @logger.info("WinRM not up: #{e.inspect}")
        return false
      end
      
      def execute(command, opts=nil, &block)
        opts = {
          :error_check => true,
          :error_class => Errors::WinRMExecutionError,
          :error_key   => :winrm_bad_exit_status,
          :command     => command,
          :sudo        => false,
          :shell       => :powershell
        }.merge(opts || {})

        if opts[:shell].eql? :powershell
          command = VagrantWindows.load_script("command_alias.ps1") << "\r\n" << command
        end
        exit_status = 0
        
        begin
          # Connect via WinRM and execute the command in the shell.
          exceptions = [
              HTTPClient::KeepAliveDisconnected,
              WinRM::WinRMHTTPTransportError,
              Errno::EACCES,
              Errno::EADDRINUSE,
              Errno::ECONNREFUSED,
              Errno::ECONNRESET,
              Errno::ENETUNREACH,
              Errno::EHOSTUNREACH,
              Timeout::Error
          ]
          exit_status = retryable(:tries => @machine.config.winrm.max_tries, :on => exceptions, :sleep => 10) do
            shell_execute(command, opts[:shell], &block)
          end
        rescue StandardError => e
          # return a more specific auth error for 401 errors
          if e.message.include?("401")
            raise Errors::WinRMAuthorizationError,
              :user => @machine.config.winrm.username,
              :password => @machine.config.winrm.password,
              :endpoint => endpoint,
              :message => e.message 
          end
          # failed for an unknown reason, didn't even get an exit status
          raise Errors::WinRMExecutionError,
            :shell => opts[:shell],
            :command => command,
            :message => e.message
        end

        # Check for any exit status errors
        if opts[:error_check] && exit_status != 0
          error_opts = opts.merge(:_key => opts[:error_key], :exit_status => exit_status)
          raise error_opts[:error_class], error_opts 
        end

        exit_status
      end
      
      # Wrap Sudo in execute.... One day we could integrate with UAC, but Icky
      def sudo(command, opts=nil, &block)
        execute(command, opts, &block)
      end
      
      def download(from, to=nil)
        @logger.warn("Downloading: #{from} to #{to} not supported on Windows guests")
      end
      
      def test(command, opts=nil)
        # HACK: to speed up Vagrant 1.2 OS detection, skip checking for *nix OS
        return false if not (command =~ /^uname|^cat \/etc|^cat \/proc|grep 'Fedora/).nil?
        
        opts = { :error_check => false }.merge(opts || {})
        execute(command, opts) == 0
      end

      def upload(from, to)
        opts = {
            :error_check => true,
            :error_class => Errors::WinRMExecutionError,
            :error_key   => :winrm_bad_exit_status,
            :sudo        => false,
            :shell       => :powershell,
            :from        => from,
            :to          => to
        }.merge(opts || {})
        exit_status = 0
        begin
          # Connect via WinRM and execute the command in the shell.
          exceptions = [
              HTTPClient::KeepAliveDisconnected,
              WinRM::WinRMHTTPTransportError,
              Errno::EACCES,
              Errno::EADDRINUSE,
              Errno::ECONNREFUSED,
              Errno::ECONNRESET,
              Errno::ENETUNREACH,
              Errno::EHOSTUNREACH,
              Timeout::Error
          ]
          exit_status = retryable(:tries => @machine.config.winrm.max_tries, :on => exceptions, :sleep => 10) do
            do_upload(from, to)
          end
        rescue StandardError => e
          # return a more specific auth error for 401 errors
          if e.message.include?("401")
            raise Errors::WinRMAuthorizationError,
                  :user => @machine.config.winrm.username,
                  :password => @machine.config.winrm.password,
                  :endpoint => endpoint,
                  :message => e.message
          end
          # failed for an unknown reason, didn't even get an exit status
          raise Errors::WinRMExecutionError,
                :shell => opts[:shell],
                :message => e.message
        end
        # Check for any exit status errors
        if opts[:error_check] && exit_status != 0
          error_opts = opts.merge(:_key => opts[:error_key], :exit_status => exit_status)
          raise error_opts[:error_class], error_opts
        end

        exit_status
      end
      
      def do_upload(from, to)
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
          out = session.cmd( "echo #{chunk.join} >> \"#{file_name}\"" )
        end
        execute "mkdir $([System.IO.Path]::GetDirectoryName(\"#{to}\"))"
        execute <<-EOH
          $base64_string = Get-Content \"#{file_name}\"
          $bytes  = [System.Convert]::FromBase64String($base64_string) 
          $new_file = [System.IO.Path]::GetFullPath(\"#{to}\")
          [System.IO.File]::WriteAllBytes($new_file,$bytes)
        EOH
      end

      def new_session
        opts = endpoint_options()
        logger.debug("Creating WinRM session to #{endpoint} with options: #{opts}")

        client = ::WinRM::WinRMWebService.new(endpoint, :plaintext, opts)
        client.set_timeout(opts[:operation_timeout])
        client.toggle_nori_type_casting(:off) #we don't want coersion of types
        client
      end

      def session
        @session ||= new_session
      end

      protected

      def endpoint_options
        {
          :user => @machine.config.winrm.username,
          :pass => @machine.config.winrm.password,
          :host => winrm_host(),
          :port => winrm_port(),
          :operation_timeout => @machine.config.winrm.timeout,
          :basic_auth_only => true
        }.merge ({})
      end

      def winrm_host
        @winrm_host ||= find_winrm_host()
      end
      
      def winrm_port
        @winrm_port ||= find_winrm_host_port()
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
      
        # Look for the forwarded port only by comparing the guest port. VMware providers do not currently provide read_forwarded_ports
        if (@machine.provider_name != :vmware_fusion) && (@machine.provider_name != :vmware_workstation)
          @machine.provider.driver.read_forwarded_ports.each do |_, _, hostport, guestport|
            return hostport if guestport == expected_guest_port
          end
        end

        @machine.config.winrm.port
      end

      def endpoint
        if !@winrm_endpoint
          opts = endpoint_options()
          @winrm_endpoint = "http://#{opts[:host]}:#{opts[:port]}/wsman"
        end
        @winrm_endpoint
      end    

      # Executes the command on an SSH connection within a login shell.
      def shell_execute(command, shell=:powershell, &block)
        @logger.debug("#{shell} executing:\n#{command}")
        
        if shell.eql? :cmd
          output = session.cmd(command) do |out, err|
            handle_out(:stdout, out, &block)
            handle_out(:stderr, err, &block)
          end
        elsif shell.eql? :powershell
          output = session.powershell(command) do |out, err|
            handle_out(:stdout, out, &block)
            handle_out(:stderr, err, &block)
          end
        else
          raise Errors::WinRMInvalidShell, :shell => shell
        end

        exit_status = output[:exitcode]
        @logger.debug("Exit status: #{exit_status.inspect}")

        # Return the final exit status
        return exit_status
      end
      
      def handle_out(type, data, &block)
        if block_given? && data
          if data =~ /\n/
            data.split(/\n/).each { |d| block.call(type, d) }
          else
            block.call(type, data)
          end
        end
      end

    end #WinRM class
  end
end
