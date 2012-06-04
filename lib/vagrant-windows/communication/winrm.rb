require 'timeout'

require 'log4r'
#require 'em-winrm'
require 'winrm'
require 'highline'

require 'vagrant/util/ansi_escape_code_remover'
require 'vagrant/util/file_mode'
require 'vagrant/util/platform'
require 'vagrant/util/retryable'

module Vagrant
  module Communication
    # Provides communication with the VM via WinRM.
    class WinRM < Base

      include Util::ANSIEscapeCodeRemover
      include Util::Retryable

      attr_reader :logger
      attr_reader :vm

      def initialize(vm)
        @vm     = vm
        @logger = Log4r::Logger.new("vagrant::communication::winrm")
        @co = nil
      end

      def ready?
        logger.debug("Checking whether WinRM is ready...")

        Timeout.timeout(@vm.config.winrm.timeout) do
          execute "hostname"
        end

        # If we reached this point then we successfully connected
        logger.info("WinRM is ready!")
        true
      rescue Timeout::Error => e
        #, Errors::SSHConnectionRefused, Net::SSH::Disconnect => e
        # The above errors represent various reasons that WinRM may not be
        # ready yet. Return false.
        logger.info("WinRM not up yet: #{e.inspect}")

        return false
      end

      # Wrap Sudo in execute.... One day we could integrate with UAC, but Icky
      def sudo(command, opts=nil, &block)
        execute(command,opts,&block)
      end
      
      def execute(command, opts=nil, &block)

        # Connect to WinRM, giving it a few tries
        logger.info("Connecting to WinRM: #{@vm.winrm.info[:host]}:#{@vm.winrm.info[:port]}")

        opts = {
          :error_check => true,
          :error_class => Errors::VagrantError,
          :error_key   => :winrm_bad_exit_status,
          :command     => command,
          :sudo        => false,
          :shell      => :powershell
        }.merge(opts || {})

        # Connect via WinRM and execute the command in the shell.
        exceptions = [HTTPClient::KeepAliveDisconnected] 
        exit_status = retryable(:tries => @vm.config.winrm.max_tries,   :on => exceptions, :sleep => 10) do
          logger.debug "WinRM Trying to connect"
          shell_execute(command,opts[:shell], &block)
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

      def new_session
        opts = {
          :user => vm.config.winrm.username,
          :pass => vm.config.winrm.password,
          :host => vm.config.winrm.host,
          :port => vm.winrm.info[:port],
          :basic_auth_only => true
        }.merge ({})

        # create a session
        begin
          endpoint = "http://#{opts[:host]}:#{opts[:port]}/wsman"
          client = ::WinRM::WinRMWebService.new(endpoint, :plaintext, opts)
          client.set_timeout(opts[:operation_timeout]) if opts[:operation_timeout]
        rescue ::WinRM::WinRMAuthorizationError => error
          raise ::WinRM::WinRMAuthorizationError.new("#{error.message}@#{opts[:host]}")
        end
        client.max_env_size 32768
        client
      end
      
      def session
        @session ||= new_session
      end
      
      def h
        @highline ||= HighLine.new
      end
      
      def print_data(data, color = :cyan)
        if data =~ /\n/
          data.split(/\n/).each { |d| print_data(d, color) }
        else
          puts "#{h.color('winrm', color)} #{data.chomp}"
        end
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

      protected

      # Executes the command on an SSH connection within a login shell.
      def shell_execute(command,shell = :powershell)
        logger.info("Execute: #{command}")
        exit_status = nil

        if shell.eql? :cmd
          output = session.cmd(command) do |out,error|
            print_data(out) if out
            print_data(error) if error
          end  
        elsif shell.eql? :powershell
          new_command = File.read(File.expand_path("#{File.dirname(__FILE__)}/../scripts/command_alias.ps1"))
          new_command << "\r\n"
          new_command << command
          output = session.powershell(new_command) do |out,error|
            print_data(out) if out
            print_data(error) if error
          end
        else
          raise Vagrant::Errors::WinRMInvalidShell, "#{shell} is not a valid type of shell"
        end   
        
        exit_status = output[:exitcode]
        logger.debug exit_status.inspect

        # Return the final exit status
        return exit_status
      end
    end
  end
end