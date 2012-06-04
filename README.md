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
  