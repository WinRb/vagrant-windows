 Building a Base Box
 ===================
 
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

  - Turn off UAC
  - Disable Shutdown Tracker
  
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

What Works?
===========
- vagrant up|hault|reload|provision
- Chef Vagrant Provisioner

What has not been tested
========================
- Everything Else!!!
- Shell and Puppet Provisioners 
  - Shell should work, though I have not vetted it yet.

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
Chris McClimans - Vagrant Branch (https://github.com/hh/vagrant/blob/feature/winrm/)
Dan Wanek - WinRM GEM (https://github.com/zenchild/WinRM)
  +1 For being super responsive to pull requests.