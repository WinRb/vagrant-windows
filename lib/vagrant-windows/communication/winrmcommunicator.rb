require 'timeout'
require 'log4r'
require_relative '../errors'
require_relative '../windows_machine'
require_relative 'winrmshell'
require_relative 'winrmshell_factory'
require_relative 'winrmfinder'

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
        return false
      end
      
      def execute(command, opts={}, &block)
        if opts[:shell].eql? :cmd
          winrmshell.cmd(command, &block)[:exitcode]
        else
          command = VagrantWindows.load_script("command_alias.ps1") << "\r\n" << command
          winrmshell.powershell(command, &block)[:exitcode]
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
        winrmshell.upload(from, to)
      end
      
      def download(from, to=nil)
        @logger.warn("Downloading: #{from} to #{to} not supported on Windows guests")
      end
      
      def winrmshell=(winrmshell)
        @winrmshell = winrmshell
      end
      
      def winrmshell
        @winrmshell ||= @winrm_shell_factory.create_winrm_shell()
      end
      
    end #WinRM class
  end
end
