# Vagrant-Windows
[![Build Status](https://travis-ci.org/WinRb/vagrant-windows.png)](https://travis-ci.org/WinRb/vagrant-windows)
[![Code Climate](https://codeclimate.com/github/WinRb/vagrant-windows.png)](https://codeclimate.com/github/WinRb/vagrant-windows)
[![Gem Version](https://badge.fury.io/rb/vagrant-windows.png)](http://badge.fury.io/rb/vagrant-windows)

Use Windows guests with Vagrant

## Getting Started
1. Install the vagrant-windows plugin.
2. Create and configure a Windows guest base box.
3. Create a Vagrantfile.
4. vagrant up

## Installation

- For Vagrant 1.1 and above execute `vagrant plugin install vagrant-windows`.
- For Vagrant 1.0 execute `vagrant plugin install vagrant-windows --plugin-version 0.1.2`.

## Creating a Base Box

Supported Guest Operating Systems:
- Windows 7
- Windows 8
- Windows Server 2008
- Windows Server 2008 R2
- Windows Server 2012

Windows Server 2003 and Windows XP are not supported by the maintainers of this project. Any issues regarding any unsupported guest OS will be closed. If you still insist on using XP or Server 2003, [this](http://stackoverflow.com/a/18593425/18475) may help.

You'll need to create a new Vagrant base box. Create a new Windows VM in VirtualBox, configure some Windows settings (see below) then follow the [Vagrant packaging instructions](http://docs.vagrantup.com/v2/cli/package.html).

  - Create a vagrant user, for things to work out of the box username and password should both be "vagrant".
  - Turn off UAC (Msconfig)
  - Disable complex passwords
  - [Disable Shutdown Tracker](http://www.jppinto.com/2010/01/how-to-disable-the-shutdown-event-tracker-in-server-20032008/) on Windows 2008/2012 Servers (except Core).
  - [Disable "Server Manager" Starting at login](http://www.elmajdal.net/win2k8/How_to_Turn_Off_The_Automatic_Display_of_Server_Manager_At_logon.aspx) on Windows 2008/2012 Servers (except Core).
  - Enable and configure WinRM (see below)

### WinRM Configuration

These commands assume you're running from a regular command window and not PowerShell.
```
   winrm quickconfig -q
   winrm set winrm/config/winrs @{MaxMemoryPerShellMB="512"}
   winrm set winrm/config @{MaxTimeoutms="1800000"}
   winrm set winrm/config/service @{AllowUnencrypted="true"}
   winrm set winrm/config/service/auth @{Basic="true"}
   sc config WinRM start= auto
```

#### Additional WinRM 1.1 Configuration

These additional configuration steps are specific to Windows7 and Windows Server 2008 (WinRM 1.1). For Windows Server 2008 R2 and newer you can ignore this section.

1. Ensure the Windows PowerShell feature is installed
2. [change the default WinRM port](http://technet.microsoft.com/en-us/library/ff520073(v=ws.10).aspx) - see below or [upgrade to WinRM 2.0](http://www.microsoft.com/en-us/download/details.aspx?id=20430).
```
netsh firewall add portopening TCP 5985 "Port 5985"
winrm set winrm/config/listener?Address=*+Transport=HTTP @{Port="5985"}
```

### Required Windows Services

If you like to turn off optional Windows services you'll need to ensure you leave these services enabled for vagrant-windows to continue to work:

  - Base Filtering Engine
    - Remote Procedure Call (RPC)
      - DCOM Server Process Launcher
      - RPC Endpoint Mapper
  - Windows Firewall
  - Windows Remote Management (WS-Management)
  
## The Vagrant File

Add the following to your Vagrantfile

```ruby
config.vm.guest = :windows
config.windows.halt_timeout = 25
config.winrm.username = "vagrant"
config.winrm.password = "vagrant"
config.vm.network :forwarded_port, guest: 5985, host: 5985
```

Example:
```ruby
Vagrant.configure("2") do |config|
  
  # Max time to wait for the guest to shutdown
  config.windows.halt_timeout = 25
  
  # Admin user name and password
  config.winrm.username = "vagrant"
  config.winrm.password = "vagrant"

  # Configure base box parameters
  config.vm.box = "vagrant-windows2008r2"
  config.vm.box_url = "./vagrant-windows2008r2.box"
  config.vm.guest = :windows

  # Port forward WinRM and RDP
  config.vm.network :forwarded_port, guest: 3389, host: 3389
  config.vm.network :forwarded_port, guest: 5985, host: 5985
  
end
````

Available Config Parameters:

* ```config.windows.halt_timeout``` - How long Vagrant should wait for the guest to shutdown before forcing exit, defaults to 30 seconds
* ```config.windows.halt_check_interval``` - How often Vagrant should check if the system has shutdown, defaults to 1 second
* ```config.windows.set_work_network``` - Force network adapters to "Work Network". Useful for Win7 guests using private networking.
* ```config.winrm.username``` - The Windows guest admin user name, defaults to vagrant.
* ```config.winrm.password``` - The above's password, defaults to vagrant.
* ```config.winrm.host``` - The IP of the guest, but because we use NAT with port forwarding this defaults to localhost.
* ```config.winrm.guest_port``` - The guest's WinRM port, defaults to 5985.
* ```config.winrm.port``` - The WinRM port on the host, defaults to 5985. You might need to change this if your hosts is also Windows.
* ```config.winrm.max_tries``` - The number of retries to connect to WinRM, defaults to 20.
* ```config.winrm.timeout``` - The max number of seconds to wait for a WinRM response, defaults to 1800 seconds.

Note - You need to ensure you specify a config.windows and a config.winrm in your Vagrantfile. Currently there's a problem where Vagrant will not load the plugin config even with defaults if at least one of its values doesn't exist in the Vagrantfile.



------------------------------------------------------------

## What Works?

- vagrant up|halt|reload|provision
- Chef Vagrant Provisioner
- Puppet Vagrant Provisioner
- Shell Vagrant provisioner. Batch files or PowerShell (ps1) scripts are supported as well as inline scripts.


## Troubleshooting

#### When I run the winrm command I get: "Error: Invalid use of command line. Type "winrm -?" for help."
- You're running the winrm command from powershell. You need to put ```@{MaxMemoryPerShellMB="512"}``` etc in single quotes:
```
   winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="512"}'
```

#### I get a 401 auth error from WinRM
- Ensure you've followed the WinRM configuration instructions above.
- Ensure you can manually login using the specified config.winrm.username you've specified in your Vagrantfile.
- Ensure your password hasn't expired.
- Ensure your password doesn't need to be changed because of policy.

#### I get a non-401 error from WinRM waiting for the VM to boot
- Ensure you've properly setup port forwarding of WinRM
- Make sure your VM can boot manually through VBox.

#### SQL Server cookbook fails to install through Vagrant
- Ensure UAC is turned off
- Ensure your vagrant user is an admin on the guest
- The SQL Server installer uses a lot of resources, ensure WinRM Quota Management is properly configured to give it enough resources.
- See [COOK-1172](http://tickets.opscode.com/browse/COOK-1172) and http://stackoverflow.com/a/15235996/82906 for more information.

If all else fails try running [vagrant with debug logging](http://docs.vagrantup.com/v2/debugging.html), perhaps that will give
you enough insight to fix the problem or file an issue.


## Contributing

1. Fork it.
2. Create a branch (git checkout -b my_feature_branch)
3. Commit your changes (git commit -am "Added a sweet feature")
4. Push to the branch (git push origin my_feature_branch)
5. Create a pull requst from your branch into master (Please be sure to provide enough detail for us to cipher what this change is doing)

### Development

Clone this repository and use [Bundler](http://gembundler.com) to get the dependencies:

```
$ bundle install
```

Once you have the dependencies, you can run the tests with `rake`:

```
$ bundle exec rake spec
```

If those pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by just
creating a [Vagrantfile](http://docs.vagrantup.com/v2/plugins/packaging.html)
in the top level of this directory (it is gitignored) that uses it, and
use bundler to execute Vagrant:

```
$ bundle exec vagrant up
```

### Installing Vagrant-Windows From Source

If you want to globally install your locally built plugin from source, use the following method (this would be for 1.2.0):

```
 bundle install
 bundle exec rake build
 vagrant plugin install pkg/vagrant-windows-1.2.0.gem
```

Keep in mind you should have Ruby 1.9.3 and Ruby DevKit installed. Check out the following gist that can get you what you need (from blank system to fully ready): [Install Vagrant Windows Plugin From Source Gist](https://gist.github.com/ferventcoder/6251225).

## References and Shout Outs

- Chris McClimans - Vagrant Branch (https://github.com/hh/vagrant/blob/feature/winrm/)
- Dan Wanek - WinRM GEM (https://github.com/zenchild/WinRM)
  - +1 For being super responsive to pull requests.
- Mike Griffen - Added first vagrant-windows unit tests and updated readme
- Geronimo Orozco - Shell provisioner support
- David Cournapeau - Added config.windows.set_work_network option
- keiths-osc - Fixed Vagrant 1.2 shared folder action
- Rob Reynolds - Updated readme installation and box configuration notes
- stonith - Updated readme winrm config notes
- wenns - Updated readme to advise against forwarding RDP
- Joe Fitzgerald - Added VMWare support and improved retry logic.
