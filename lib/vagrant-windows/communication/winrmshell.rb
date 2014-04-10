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
      
      def upload(from, to)
        @logger.debug("Upload: #{from} -> #{to}")
        if File.directory?(from)
          Dir.glob(File.join(from, '**/*')) do |entry|
            if !File.directory?(entry)
              rel_path = File.dirname(entry[from.length, entry.length])
              dest = File.join(to, rel_path, File.basename(entry))
              upload_file(entry, dest)
            end
          end
        else
          upload_file(from, to)
        end
      end

      def download(from, to)
        @logger.debug("Downloading: #{from} -> #{to}")
        output = powershell("[System.convert]::ToBase64String([System.IO.File]::ReadAllBytes(\"#{from}\"))")
        contents = output[:data].map!{|line| line[:stdout]}.join.gsub("\\n\\r", '')
        out = Base64.decode64(contents)
        IO.binwrite(to, out)
      end

      protected

      # Uploads the given file, but only if the target file doesn't exist
      # or its MD5 checksum doens't match the host's source checksum.
      #
      # @param [String] The source file path on the host
      # @param [String] The destination file path on the guest
      def upload_file(from, to)
        if should_upload_file?(from, to)
          @logger.debug("Uploading: #{to}")
          File.open(from, 'rb') do |f|
            begin
              chunk = Base64.encode64(f.read(8000))
              chunk.gsub!("\n", '')
              powershell("Add-Content -Path \"#{to}\" -Encoding byte -Value ([System.Convert]::FromBase64String(\"#{chunk.chomp}\"))\r\n")
            end until f.eof?
          end
        else
          @logger.debug("Up to date: #{to}")
        end
      end

      # Checks to see if the target file on the guest is missing or out of date.
      #
      # @param [String] The source file path on the host
      # @param [String] The destination file path on the guest
      # @return [Boolean] True if the file needs to be uploaded
      def should_upload_file?(from, to)
        local_md5 = Digest::MD5.file(from).hexdigest
        cmd = <<-EOH
          if (Test-Path '#{to}') {
            $hash_algo = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
            $file = [System.IO.File]::Open('#{to}', [System.IO.Filemode]::Open, [System.IO.FileAccess]::Read)
            $md5 = ([System.BitConverter]::ToString($hash_algo.ComputeHash($file))).Replace("-","").ToLower()
            $file.Dispose()
            if ($md5 -eq '#{local_md5}') {
              exit 0
            }
            else {
              rm #{to}
            }
          }
          exit 1
        EOH
        powershell(cmd)[:exitcode] == 1
      end
      
      def execute_shell(command, shell=:powershell, &block)
        raise Errors::WinRMInvalidShell, :shell => shell unless shell == :cmd || shell == :powershell
        begin
          execute_shell_with_retry(command, shell, &block)
        rescue => e
          raise_winrm_exception(e, shell, command)
        end
      end
      
      def execute_shell_with_retry(command, shell, &block)
        retryable(:tries => @max_tries, :on => @@exceptions_to_retry_on, :sleep => 10) do
          @logger.debug("#{shell} executing:\n#{command}")
          output = session.send(shell, command) do |out, err|
            block.call(:stdout, out) if block_given? && out
            block.call(:stderr, err) if block_given? && err
          end
          @logger.debug("Exit status: #{output[:exitcode].inspect}")
          return output
        end
      end
      
      def execute_wql(query)
        retryable(:tries => @max_tries, :on => @@exceptions_to_retry_on, :sleep => 10) do
          @logger.debug("#executing wql: #{query}")
          output = session.wql(query)
          @logger.debug("wql result: #{output.inspect}")
          return output
        end
      rescue => e
        raise_winrm_exception(e, :wql, query)
      end
      
      def raise_winrm_exception(winrm_exception, shell, command)
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
