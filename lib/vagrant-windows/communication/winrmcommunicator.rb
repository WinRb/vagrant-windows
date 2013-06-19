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
        ready = session.ready?
        @logger.debug("WinRM ready?: #{ready}")
        ready
      end
      
      def execute(command, opts=nil, &block)
        exit_status = 0
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
        ensure
          @session.disconnect
          @session = nil
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
        @logger.debug("Uploading: #{from} to #{to}")
        file_manager = WinRM::FileManager.new(session)
        file_manager.send_file(from, to, :overwrite => true)
      end

      def session
        @session ||= new_session
      end

      protected
      
      def new_session
        opts = endpoint_options()
        logger.debug("Creating WinRM session to #{@machine.config.winrm.host} with options: #{opts}")
        ::WinRM::Client.new(@machine.config.winrm.host, opts)
      end

      def endpoint_options
        {
          :user => @machine.config.winrm.username,
          :pass => @machine.config.winrm.password,
          :port => winrm_port,
          :ssl => true,
          :timeout => 'PT1800S'  #@machine.config.winrm.timeout,
        }.merge ({})
      end
      
      def winrm_port
        @winrm_port ||= find_winrm_host_port()
      end
      
      def find_winrm_host_port
        expected_guest_port = @machine.config.winrm.guest_port
        @logger.debug("Searching for WinRM port: #{expected_guest_port.inspect}")
      
        # Look for the forwarded port only by comparing the guest port
        @machine.provider.driver.read_forwarded_ports.each do |_, _, hostport, guestport|
          return hostport if guestport == expected_guest_port
        end
        
        @machine.config.winrm.port
      end

      # Executes the command on an SSH connection within a login shell.
      def shell_execute(command, shell=:powershell, &block)
        @logger.debug("#{shell} executing:\n#{command}")
        
        if shell.eql? :cmd
          return_code, output_streams = session.cmd(command) do |stream, text|
            handle_out(stream, text, &block)
          end
        elsif shell.eql? :powershell
          return_code, output_streams = session.powershell(command) do |stream, text|
            handle_out(stream, text, &block)
          end
        else
          raise Errors::WinRMInvalidShell, :shell => shell
        end

        @logger.debug("Exit status: #{return_code.inspect}")
        return_code
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
