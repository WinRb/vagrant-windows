 
Installing
==========

 ```
 gem install vagrant-windows
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
  - Create a vagrant user
    - For things to work out of the box, username and password should both be vagrant

  - Turn off UAC (Msconfig)
  - Disable complex passwords
  
Servers
--------
  - Disable Shutdown Tracker (http://www.jppinto.com/2010/01/how-to-disable-the-shutdown-event-tracker-in-server-20032008/)
  - Disable "Server Manager" Starting at login (http://www.elmajdal.net/win2k8/How_to_Turn_Off_The_Automatic_Display_of_Server_Manager_At_logon.aspx)
  
The Vagrant File
================

Add the following to your Vagrantfile

```ruby
  config.vm.guest = :windows

  config.vm.forward_port 3389, 3390, :name => "rdp", :auto => true
  config.vm.forward_port 5985, 5985, :name => "winrm", :auto => true
```

Example:
```ruby
Vagrant::Config.run do |config|

  #The following timeout configuration is option, however if have
  #any large remote_file resources in your chef recipes, you may
  #experience timeouts (reported as 500 responses)
  config.winrm.timeout = 1800     #Set WinRM Timeout in seconds (Default 30)

  # Configure base box parameters
  config.vm.box = "windows2008r2"
  config.vm.box_url = "./windows-2008-r2.box"
  config.vm.guest = :windows

  config.vm.forward_port 3389, 3390, :name => "rdp", :auto => true
  config.vm.forward_port 5985, 5985, :name => "winrm", :auto => true

  config.vm.provision :chef_solo do |chef|
    chef.add_recipe("your::recipe")
  end

end
````

What Works?
===========
- vagrant up|hault|reload|provision
- Chef Vagrant Provisioner

What has not been tested
========================
- Everything Else!!!
- Shell and Puppet Provisioners 
  - Shell should work, though I have not vetted it yet.

What does not work
==================
- <s>Complex networking setups</s> - Fixed in 0.0.3
  - Note that I have not tested the Virtual Box 4.0 Driver, all _should_ work. Can someone please confirm?

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
-Dan Wanek - WinRM GEM (https://github.com/zenchild/WinRM)
  - +1 For being super responsive to pull requests.


Changelog
=========
0.1.1 - Remove extra debug information from command output.