Set-ExecutionPolicy Unrestricted -force;

"running" | Out-File c:\tmp\chef-solo.running

$cmd = "c:\opscode\chef\bin\chef-solo.bat"
$arguments = "-c c:\tmp\vagrant-chef-1\solo.rb -j c:\tmp\vagrant-chef-1\dna.json"
$stdOutLog = "c:\tmp\chef-solo.log"
$stdErrLog = "c:\tmp\chef-solo.error.log"

Start-Process $cmd -ArgumentList $arguments -NoNewWindow -Wait -RedirectStandardOutput $stdOutLog -RedirectStandardError $stdErrLog

del c:\tmp\chef-solo.running
