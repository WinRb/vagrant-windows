require 'timeout'

require 'log4r'
require 'winrm'
require 'highline'

require 'vagrant/util/ansi_escape_code_remover'
require 'vagrant/util/file_mode'
require 'vagrant/util/platform'
require 'vagrant/util/retryable'

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
        @winrm = WinRM.new(machine)
        @logger = Log4r::Logger.new("vagrant_windows::communication::winrmcommunicator")
        @co = nil
        
        @logger.debug("initializing WinRMCommunicator")
      end

      def ready?
        logger.debug("Checking whether WinRM is ready...")

        Timeout.timeout(@machine.config.winrm.timeout) do
          execute "hostname"
        end

        # If we reached this point then we successfully connected
        logger.debug("WinRM is ready!")
        true
      rescue Timeout::Error, HTTPClient::KeepAliveDisconnected => e
        #, Errors::SSHConnectionRefused, Net::SSH::Disconnect => e
        # The above errors represent various reasons that WinRM may not be
        # ready yet. Return false.
        logger.debug("WinRM not up yet: #{e.inspect}")

        return false
      end
      
      def execute(command, opts=nil, &block)
        opts = {
          :error_check => true,
          :error_class => ::Vagrant::Errors::VagrantError,
          :error_key   => :winrm_bad_exit_status,
          :command     => command,
          :sudo        => false,
          :shell       => :powershell
        }.merge(opts || {})

        # HACK: Ensure credential delegation is supported on the guest (COOK-1172)
        if command.include?("chef-solo -c")
          chefsolo_command = command
          command = load_script("ps_runas.ps1") << "\r\n" << "exit ps-runas \"#{@machine.config.winrm.username}\" \"#{@machine.config.winrm.password}\" \"powershell.exe\" \"-Command #{chefsolo_command}\""
        else
          command = load_script("command_alias.ps1") << "\r\n" << command
        end
        
        # Connect via WinRM and execute the command in the shell.
        exceptions = [HTTPClient::KeepAliveDisconnected] 
        exit_status = retryable(:tries => @machine.config.winrm.max_tries, :on => exceptions, :sleep => 10) do
          shell_execute(command, opts[:shell], &block)
        end

        logger.debug("#{command} EXIT STATUS #{exit_status.inspect}")

        # Check for any errors
        if opts[:error_check] && exit_status != 0
          # The error classes expect the translation key to be _key,
          # but that makes for an ugly configuration parameter, so we
          # set it here from `error_key`
          error_opts = opts.merge(:_key => opts[:error_key])
          raise opts[:error_class], error_opts
        end

        # Return the exit status
        exit_status
      end
      
      # Wrap Sudo in execute.... One day we could integrate with UAC, but Icky
      def sudo(command, opts=nil, &block)
        execute(command, opts, &block)
      end
      
      def download(from, to=nil)
        @logger.debug("Downloading: #{from} to #{to}")

        #TODO: Download impl!
        #scp_connect do |scp|
        #  scp.download!(from, to)
        #end
      end
      
      def test(command, opts=nil)
        #TODO: Does this work? Copied from Vagrant
        opts = { :error_check => false }.merge(opts || {})
        execute(command, opts) == 0
      end
      
      def upload(from, to)
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
        execute "mkdir [System.IO.Path]::GetDirectoryName(\"#{to}\")"
        execute <<-EOH
          $base64_string = Get-Content \"#{file_name}\"
          $bytes  = [System.Convert]::FromBase64String($base64_string) 
          $new_file = [System.IO.Path]::GetFullPath(\"#{to}\")
          [System.IO.File]::WriteAllBytes($new_file,$bytes)
        EOH
      end

      def new_session
        opts = {
          :user => @machine.config.winrm.username,
          :pass => @machine.config.winrm.password,
          :host => @machine.config.winrm.host,
          :port => @machine.config.winrm.port,
          :operation_timeout => @machine.config.winrm.timeout,
          :basic_auth_only => true
        }.merge ({})
        endpoint = "http://#{opts[:host]}:#{opts[:port]}/wsman"

        logger.debug("Creating WinRM session to #{endpoint} with options: #{opts}")
        
        begin
          client = ::WinRM::WinRMWebService.new(endpoint, :plaintext, opts)
          client.set_timeout(opts[:operation_timeout])
        rescue ::WinRM::WinRMAuthorizationError => e
          raise Errors::WinRMAuthorizationError,
            :user => opts[:user],
            :password => opts[:pass],
            :endpoint => endpoint,
            :message => e.message
        end

        client
      end
      
      def session
        @session ||= new_session
      end
      
      def h
        @highline ||= HighLine.new
      end
      
      def print_data(data, color = :green)
        if data =~ /\n/
          data.split(/\n/).each { |d| print_data(d, color) }
        else
          puts h.color(data.chomp, color)
        end
      end

      protected

      # Executes the command on an SSH connection within a login shell.
      def shell_execute(command, shell = :powershell)
        exit_status = nil
        
        @logger.debug("#{shell} executing remote: #{command}")
        
        begin
          if shell.eql? :cmd
            output = session.cmd(command) do |out,error|
              print_data(out) if out
              print_data(error, :red) if error
            end  
          elsif shell.eql? :powershell
            output = session.powershell(command) do |out,error|
              print_data(out) if out
              print_data(error, :red) if error
            end
          else
            raise Errors::WinRMInvalidShell, :shell => shell
          end

          exit_status = output[:exitcode]
          @logger.debug exit_status.inspect

          # Return the final exit status
          return exit_status
        rescue StandardError => e
          raise Errors::WinRMExecutionError,
            :shell => shell,
            :command => command,
            :message => e.message
        end
      end
      
      def load_script(script_file_name)
        File.read(File.expand_path("#{File.dirname(__FILE__)}/../scripts/#{script_file_name}"))
      end
        
    end #WinRM class
  end
end