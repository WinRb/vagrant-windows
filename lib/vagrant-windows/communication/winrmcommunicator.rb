require 'timeout'
require 'winrm'
require 'log4r'
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
        @logger = Log4r::Logger.new("vagrant_windows::communication::winrmcommunicator")
        @logger.debug("initializing WinRMCommunicator")
      end

      def ready?
        logger.debug("Checking whether WinRM is ready...")
        
        Timeout.timeout(@machine.config.winrm.timeout) do
          execute("hostname") do |type, data|
            @logger.debug("hostname: #{data}")
          end
        end

        # If we reached this point then we successfully connected
        logger.debug("WinRM is ready!")
        true
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

        # HACK: Ensure credential delegation is supported on the guest (COOK-1172)
        if command.include?("chef-solo -c")
          chefsolo_command = command
          command = load_script("ps_runas.ps1") << "\r\n" << "exit ps-runas \"#{@machine.config.winrm.username}\" \"#{@machine.config.winrm.password}\" \"powershell.exe\" \"-Command #{chefsolo_command}\""
        else
          command = load_script("command_alias.ps1") << "\r\n" << command
        end
        
        exit_status = 0
        begin
          # Connect via WinRM and execute the command in the shell.
          exceptions = [HTTPClient::KeepAliveDisconnected] 
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
        logger.debug("#{command} EXIT STATUS #{exit_status.inspect}")
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
          :host => @machine.config.winrm.host,
          :port => @machine.config.winrm.port,
          :operation_timeout => @machine.config.winrm.timeout,
          :basic_auth_only => true
        }.merge ({})
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
        @logger.debug("#{shell} executing remote: #{command}")
        
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
        @logger.debug exit_status.inspect

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
      
      def load_script(script_file_name)
        File.read(File.expand_path("#{File.dirname(__FILE__)}/../scripts/#{script_file_name}"))
      end
        
    end #WinRM class
  end
end