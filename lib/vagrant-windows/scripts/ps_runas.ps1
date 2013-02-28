function ps-runas ([String] $user, [String] $password, [String] $cmd, [String] $arguments)
{
  $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force

  $process = New-Object System.Diagnostics.Process
  $setup = $process.StartInfo
  $setup.FileName = $cmd
  $setup.Arguments = $arguments
  $setup.UserName = $user
  $setup.Password = $secpasswd
  $setup.Verb = "runas"
  $setup.UseShellExecute = $false
  $setup.RedirectStandardError = $true
  $setup.RedirectStandardOutput = $true
  $setup.RedirectStandardInput = $false
  
  # Hook into the standard output and error stream events
  $errEvent = Register-ObjectEvent -InputObj $process `
  	-Event "ErrorDataReceived" `
  	-Action `
  	{
  		param
  		(
  			[System.Object] $sender,
  			[System.Diagnostics.DataReceivedEventArgs] $e
  		)
  		Write-Host $e.Data
  	}
  $outEvent = Register-ObjectEvent -InputObj $process `
  	-Event "OutputDataReceived" `
  	-Action `
  	{
  		param
  		(
  			[System.Object] $sender,
  			[System.Diagnostics.DataReceivedEventArgs] $e
  		)
  		Write-Host $e.Data
  	}
  
  if (!$process.Start())
  {
    Write-Host "Failed to start $cmd"
  }
  
  $process.BeginOutputReadLine()
  $process.BeginErrorReadLine()
  
  # Wait until process exit
  $process.WaitForExit()
  
  $process.CancelOutputRead()
  $process.CancelErrorRead()
  $process.Close()
}
