require 'log4r'

module Vagrant
  # Manages WINRM access to a specific environment. Allows an environment to
  # run commands, upload files, and check if a host is up.
  class WinRM

    def initialize(vm)
      @vm = vm
      @logger = Log4r::Logger.new("vagrant::winrm")
    end

    # Returns a hash of information necessary for accessing this
    # virtual machine via WINRM.
    #
    # @return [Hash]
    def info
      results = {
        :host          => @vm.config.winrm.host,
        :port          => @vm.config.winrm.port || @vm.driver.ssh_port(@vm.config.winrm.guest_port),
        :username      => @vm.config.winrm.username
      }

      # This can happen if no port is set and for some reason Vagrant
      # can't detect an SSH port.
      raise Errors::WinRMPortNotDetected if !results[:port]

      # Return the results
      return results
    end

    # Checks if this environment's machine is up (i.e. responding to WINRM).
    #
    # @return [Boolean]
    def up?
      # We have to determine the port outside of the block since it uses
      # API calls which can only be used from the main thread in JRuby on
      # Windows
      ssh_port = port

      require 'timeout'
      Timeout.timeout(@env.config.ssh.timeout) do
        execute 'hostname'
      end

      true
    rescue Timeout::Error, Errno::ECONNREFUSED
      return false
    end

    # Returns the port which is either given in the options hash or taken from
    # the config by finding it in the forwarded ports hash based on the
    # `config.ssh.forwarded_port_key`.
    def port(opts={})
      # Check if port was specified in options hash
      return opts[:port] if opts[:port]

      # Check if a port was specified in the config
      return @env.config.winrm.port if @env.config.winrm.port

      # Check if we have an SSH forwarded port
      pnum_by_name = nil
      pnum_by_destination = nil
      @logger.info("Looking for winrm port: #{opts}")
      @logger.info("Looking for winrm port: #{env.config.winrm.inspect}")

      env.vm.vm.network_adapters.each do |na| 
        # Look for the port number by destination...
        pnum_by_destination = na.nat_driver.forwarded_ports.detect do |fp|
          fp.guestport == env.config.winrm.guest_port
        end
      end

      return pnum_by_destination.hostport if pnum_by_destination

      # This should NEVER happen.
      raise Errors::WinRMPortNotDetected
    end
  end
end