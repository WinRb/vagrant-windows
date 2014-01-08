## Changelog

0.1.1
- Remove extra debug information from command output.

0.1.2
- Added virtual box 4.2 support.

0.1.3 
- Added puppet provisioner.

1.0.0 
- Converted to Vagrant 1.1.x plugin architecture.

1.0.1 
- Fix #29 Monkey Patch the 4.2 driver to include read_mac_addresses, use read_mac_addresses in all cases.

1.0.3 
- Added vagrant shell provisioner. The built-in shell provisioner tried to chmod the target script which doesn't make sense on windows.
- Can now run the vagrant-windows plugin via bundle exec instead of vagrant plugin install (for plugin dev).The vagrant src root finding logic didn't work from a bundle, but the native Vagrant src root does.
- Readme fixes/updates.

1.2.0
- Converted to Vagrant 1.2.x plugin architecture.
- Various networking fixes.
- Chef provisioner runs through the Windows task scheduler instead of ps_runas power shell script.

1.2.1
- Fixed issue 91 - drive mapping was failing on Vagrant 1.1.

1.2.2
- Reduced code duplication in WinRMShell
- Fixes issue 85 - Windows XP, 2000, 2003 officially not supported
- Fixed issue 98 - added Apache 2.0 license
- Fixed issue 104 - configuration "config.winrm.hostname" is not used
- Fixed issue 106 - WinRMCommunicator should throw an exception when a command fails by default

1.2.3
- Puppet provisioner re-establishes symbolic links (see issue 119 for Chef)
- Fixed issue 118 - chef-solo provisioner doesn't retry
- Fixed issue 119 - chef-solo provisioner fails with a CookbookNotFound error if a reboot occurs after vagrant up

1.3.0
- Added new Windows machine abstraction layer between Vagrant and vagrant-windows
- VMware should not error out when Vagrantfile contains a secondary NIC
- wql method removed from WinRM communicator
- Extracted WinRMShell factory class and added more unit tests
- Provisioners wait to start if there is a reboot pending or currently scheduled
- Fixed issue 74 - chef-solo displays error "The system cannot find the path specified" on first provision
- Fixed issue 119 - when a reboot occurs in the middle of a Chef run
- Fixed issue 125 - puppet provisioner should not error on exit code 2.
- Fixed issue 126 - cheftask.ps1 can sometimes try to read a negative number of lines
- Fixed issue 128 - Base box configuration described in readme is not correct for Windows 2008 R2 and WinRM 1.1
- Fixed issue 129 - vagrant halt fails if a provisioner has already scheduled a reboot
- Fixed issue 130 - chef-solo task now uses normal Windows task priority

1.3.1
- Fixed issue 137 - Cannot execute download script after installing the vagrant windows plugins
- Fixed issue 138 - vagrant-windows errors out for providers other than VBox or VMware

1.3.2
- Fixed issue 145 - The shell provisioner wasn't respecting file extensions for non-inline scripts.

1.4.0
- Added Vagrant 1.4.0 support, added VBox synced folder monkey patch for Vagrant 1.4
- Fixed issue 149 - Added documentation about auto_correct for winrm port
- Fixed issue 152 - Chef task fails when password contains $

1.5.0
- Support for Parallels 8/9 VMs via vagrant-parallels plugin.

1.5.1
- Fixed issue 158 - Vagrant 1.4 broke the Puppet provisioner monkey patch. Removed configure method monkey patch.
- Fixed issue 162 - Set plugin name to 'vagrant-windows' to support has_plugin? method works.
