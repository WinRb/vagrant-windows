require 'timeout'
require 'log4r'
require_relative 'winrmshell_factory'
require_relative 'winrmshell'
require_relative 'winrmfilemanager'
require_relative 'winrmfinder'
require_relative 'linux_command_filter'
require_relative '../errors'
require_relative '../windows_machine'

module VagrantWindows
  module Communication
    # Provides communication channel for Vagrant commands via WinRM.
    class WinRMCommunicator < Vagrant.plugin("2", :communicator)
      
      def self.match?(machine)
        VagrantWindows::WindowsMachine.is_windows?(machine)
      end

      def initialize(machine)
        @windows_machine = VagrantWindows::WindowsMachine.new(machine)
        @winrm_shell_factory = WinRMShellFactory.new(@windows_machine, WinRMFinder.new(@windows_machine))
        @linux_cmd_filter = LinuxCommandFilter.new()
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
        # We reset the shell to trigger calling of winrm_finder again.
        # This resolves a problem when using vSphere where the ssh_info was not refreshing
        # thus never getting the correct hostname.
        @winrmshell = nil
        return false
      end
      
      def execute(command, opts={}, &block)
        # If this is a *nix command with no Windows equivilant, don't run it
        win_friendly_cmd = @linux_cmd_filter.filter(command)
        return 0 if win_friendly_cmd.empty?

        opts = {
          :error_check => true,
          :error_class => VagrantWindows::Errors::WinRMExecutionError,
          :error_key   => :winrm_execution_error,
          :command     => win_friendly_cmd,
          :shell       => :powershell
        }.merge(opts || {})

        win_friendly_cmd << "\r\nexit $LASTEXITCODE" if opts[:shell] == :powershell
        output = winrmshell.send(opts[:shell], win_friendly_cmd, &block)

        return output if opts[:shell] == :wql
        exitcode = output[:exitcode]
        raise_execution_error(opts, exitcode) if opts[:error_check] && exitcode != 0
        exitcode
      end
      alias_method :sudo, :execute
      
      def test(command, opts=nil)
        # If this is a *nix command with no Windows equivilant, don't run it
        win_friendly_cmd = @linux_cmd_filter.filter(command)
        return false if win_friendly_cmd.empty?

        opts = { :error_check => false }.merge(opts || {})
        execute(win_friendly_cmd, opts) == 0
      end

      def upload(from, to)
        winrmshell.upload(from, to)
      end
      
      def download(from, to)
        winrmshell.download(from, to)
      end
      
      def winrmshell=(winrmshell)
        @winrmshell = winrmshell
      end
      
      def winrmshell
        @winrmshell ||= @winrm_shell_factory.create_winrm_shell()
      end

      
      protected
      
      def raise_execution_error(opts, exit_code)
        # The error classes expect the translation key to be _key, but that makes for an ugly
        # configuration parameter, so we set it here from `error_key`
        msg = "Command execution failed with an exit code of #{exit_code}"
        error_opts = opts.merge(:_key => opts[:error_key], :message => msg)
        raise opts[:error_class], error_opts
      end
      
    end #WinRM class
  end
end