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

- Fix #29 Monkey Patch the 4.2 driver to include read_mac_addresses. 
  - use read_mac_addresses in all cases.

1.0.3 

- Added vagrant shell provisioner. The built-in shell provisioner tried to chmod the target script which doesn't make sense on windows.
- Can now run the vagrant-windows plugin via bundle exec instead of vagrant plugin install (for plugin dev).The vagrant src root finding logic didn't work from a bundle, but the native Vagrant src root does.
- Readme fixes/updates.

1.2.0

- Converted to Vagrant 1.2.x plugin architecture.
- Various networking fixes.
- Chef provisioner runs through the Windows task scheduler instead of ps_runas power shell script.

1.2.1

- Fixed issue 91, drive mapping was failing on Vagrant 1.1.