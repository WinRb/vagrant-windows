
Installing Vagrant-Windows
==========================

Install Vagrant 1.1+ using the standard Vagrant installer for your platform.

Since the Vagrant 1.1 branch is not yet available via rubygem.org, you'll need to build it yourself. Clone this repo,
and from the root of the repo run:

```
rake build
vagrant plugin install pkg/vagrant-windows-0.2.0.gem
```

Building a Base Box
===================

All Windows Machines
-------------------- 
  -Enable WinRM
```
   winrm quickconfig -q
   winrm set winrm/config/winrs @{MaxMemoryPerShellMB="512"}
   winrm set winrm/config @{MaxTimeoutms="1800000"}
   winrm set winrm/config/service @{AllowUnencrypted="true"}
   winrm set winrm/config/service/auth @{Basic="true"}
```
  - Create a vagrant user, for things to work out of the box username and password should both be "vagrant".
  - Turn off UAC (Msconfig)
  - Disable complex passwords
  
Servers
--------
  - [Disable Shutdown Tracker](http://www.jppinto.com/2010/01/how-to-disable-the-shutdown-event-tracker-in-server-20032008/)
  - [Disable "Server Manager" Starting at login](http://www.elmajdal.net/win2k8/How_to_Turn_Off_The_Automatic_Display_of_Server_Manager_At_logon.aspx)
  
The Vagrant File
================

Add the following to your Vagrantfile

```ruby
config.vm.guest = :windows
config.windows.halt_timeout = 15
config.winrm.username = "vagrant"
config.winrm.password = "vagrant"
config.vm.network :forwarded_port, guest: 3389, host: 3389
config.vm.network :forwarded_port, guest: 5985, host: 5985
```

Example:
```ruby
Vagrant.configure("2") do |config|
  
  # Max time to wait for the guest to shutdown
  config.windows.halt_timeout = 15
  
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
* ```config.winrm.username``` - The Windows guest admin user name, defaults to vagrant.
* ```config.winrm.password``` - The above's password, defaults to vagrant.
* ```config.winrm.host``` - The IP of the guest, but because we use NAT with port forwarding this defaults to localhost.
* ```config.winrm.guest_port``` - The guest's WinRM port, defaults to 5985.
* ```config.winrm.port``` - The WinRM port on the host, defaults to 5985. You might need to change this if your hosts is also Windows.
* ```config.winrm.max_tries``` - The number of retries to connect to WinRM, defaults to 12.
* ```config.winrm.timeout``` - The max number of seconds to wait for a WinRM response, defaults to 1800 seconds.

Note - You need to ensure you specify a config.windows and a config.winrm in your Vagrantfile. Currently there's a problem where
Vagrant will not load the plugin config even with defaults if at least one of its values doesn't exist in the Vagrantfile.


What Works?
===========
- vagrant up|halt|reload|provision
- Chef Vagrant Provisioner

What does not work
==================
- Puppet standalone provisioning (new Vagrant plugin architecture broke this)

What has not been tested
========================
- Vagrant-Windows 0.2.0 has only been tested on an OS X host with Virtual Box 4.2.2
- Shell provisioning. Shell should work, though I have not vetted it yet.

TODOs
=========
1. Test it! We need to test on more hosts, guests, and VBox versions. Help wanted.
2. Puppet provisioner. Monkey patching the existing Vagrant puppet provisioner isn't easy now that its a plugin to core Vagrant. Ideas?
3. Unit tests. 
4. De-hackify the ps-runas chef-solo workaround for COOK-1172 and refactor WinRMCommunicator. 
5. Better docs.

Troubleshooting
===============

I get a 401 auth error from WinRM
---------------------------------
- Ensure you've followed the WinRM configuration instructions above.
- Ensure you can manually login using the specified config.winrm.username you've specified in your Vagrantfile.
- Ensure your password hasn't expired.
- Ensure your password doesn't need to be changed because of policy.

I get a non-401 error from WinRM waiting for the VM to boot
-----------------------------------------------------------
- Ensure you've properly setup port forwarding of WinRM
- Make sure your VM can boot manually through VBox.

SQL Server cookbook fails to install through Vagrant
----------------------------------------------------
- Ensure UAC is turned off
- Ensure your vagrant user is an admin on the guest
- The SQL Server installer uses a lot of resources, ensure WinRM Quota Management is properly configured to give it enough resources.
- See [COOK-1172](http://tickets.opscode.com/browse/COOK-1172) and http://stackoverflow.com/a/15235996/82906 for more information.

If all else fails try running [vagrant with debug logging](http://docs.vagrantup.com/v2/debugging.html), perhaps that will give
you enough insight to fix the problem or file an issue.

What Can I do to help?
======================
1. Contribute Code (See Below)
2. Test Various Scenarios and file bugs for things that dont work

Contributing
============
1. Fork it.
2. Create a branch (git checkout -b my_feature_branch)
3. Commit your changes (git commit -am "Added a sweet feature")
4. Push to the branch (git push origin my_feature_branch)
5. Create a pull requst from your branch into master (Please be sure to provide enough detail for us to cipher what this change is doing)


References and Shout Outs
=========================
- Chris McClimans - Vagrant Branch (https://github.com/hh/vagrant/blob/feature/winrm/)
- Dan Wanek - WinRM GEM (https://github.com/zenchild/WinRM)
  - +1 For being super responsive to pull requests.


Changelog
=========
0.1.1 - Remove extra debug information from command output.

0.1.2 - Added virtual box 4.2 support.

0.1.3 - Added puppet provisioner.

0.2.0 - Converted to Vagrant 1.1.x plugin architecture.
