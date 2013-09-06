require 'timeout'
require 'log4r'
require 'winrm'
require 'vagrant/util/retryable'
require_relative '../errors'

module VagrantWindows
  module Communication
    class WinRMShell

      include Vagrant::Util::Retryable
      
      # These are the exceptions that we retry because they represent
      # errors that are generally fixed from a retry and don't
      # necessarily represent immediate failure cases.
      @@exceptions_to_retry_on = [
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

      attr_reader :logger
      attr_reader :username
      attr_reader :password
      attr_reader :host
      attr_reader :port
      attr_reader :timeout_in_seconds
      attr_reader :max_tries

      def initialize(host, username, password, options = {})
        @logger = Log4r::Logger.new("vagrant_windows::communication::winrmshell")
        @logger.debug("initializing WinRMShell")
        
        @host = host
        @port = options[:port] || 5985
        @username = username
        @password = password
        @timeout_in_seconds = options[:timeout_in_seconds] || 60
        @max_tries = options[:max_tries] || 20
      end
      
      def powershell(command, &block)
        execute_shell(command, :powershell, &block)
      end
      
      def cmd(command, &block)
        execute_shell(command, :cmd, &block)
      end
      
      def wql(query)
        execute_wql(query)
      end

      protected
      
      def execute_shell(command, shell=:powershell, &block)
        retryable(:tries => @max_tries, :on => @@exceptions_to_retry_on, :sleep => 10) do
          @logger.debug("#{shell} executing:\n#{command}")
          if shell.eql? :cmd
            output = session.cmd(command) do |out, err|
              block.call(:stdout, out) if block_given? && out
              block.call(:stderr, err) if block_given? && err
            end
          elsif shell.eql? :powershell
            output = session.powershell(command) do |out, err|
              block.call(:stdout, out) if block_given? && out
              block.call(:stderr, err) if block_given? && err
            end
          else
            raise Errors::WinRMInvalidShell, :shell => shell
          end
          @logger.debug("Exit status: #{output[:exitcode].inspect}")
          return output
        end
      rescue => e
        handle_winrm_exception(e, shell, command)
      end
      
      def execute_wql(query)
        retryable(:tries => @max_tries, :on => @@exceptions_to_retry_on, :sleep => 10) do
          @logger.debug("#executing wql: #{query}")
          output = session.wql(query)
          @logger.debug("wql result: #{output.inspect}")
          return output
        end
      rescue => e
        handle_winrm_exception(e, :wql, query)
      end
      
      def handle_winrm_exception(winrm_exception, shell, command)
        if winrm_exception.message.include?("401") # return a more specific auth error for 401 errors
          raise Errors::WinRMAuthorizationError,
            :user => @username,
            :password => @password,
            :endpoint => endpoint,
            :message => winrm_exception.message
        end
        raise Errors::WinRMExecutionError,
          :shell => shell,
          :command => command,
          :message => winrm_exception.message
      end
      
      def new_session
        @logger.info("Attempting to connect to WinRM...")
        @logger.info("  - Host: #{@host}")
        @logger.info("  - Port: #{@port}")
        @logger.info("  - Username: #{@username}")
        
        client = ::WinRM::WinRMWebService.new(endpoint, :plaintext, endpoint_options)
        client.set_timeout(@timeout_in_seconds)
        client.toggle_nori_type_casting(:off) #we don't want coersion of types
        client
      end

      def session
        @session ||= new_session
      end
      
      def endpoint
        "http://#{@host}:#{@port}/wsman"
      end

      def endpoint_options
        { :user => @username,
          :pass => @password,
          :host => @host,
          :port => @port,
          :operation_timeout => @timeout_in_seconds,
          :basic_auth_only => true }
      end
      
    end #WinShell class
  end
end
