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
  
  $errEvent = Register-ObjectEvent -InputObj $process `
    -Event "ErrorDataReceived" `
    -Action `
    {
      param([System.Object] $sender, [System.Diagnostics.DataReceivedEventArgs] $e)
      if ($e.Data)
      {
        Write-Host $e.Data
      }
      else
      {
        New-Event -SourceIdentifier "LastMsgReceived"
      }
    }

  $outEvent = Register-ObjectEvent -InputObj $process `
    -Event "OutputDataReceived" `
    -Action `
    {
      param([System.Object] $sender, [System.Diagnostics.DataReceivedEventArgs] $e)
      Write-Host $e.Data
    }
  
  $exitCode = -1
  if ($process.Start())
  {
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()
  
    $process.WaitForExit()
    $exitCode = [int]$process.ExitCode
    Wait-Event -SourceIdentifier "LastMsgReceived" -Timeout 60 | Out-Null
  
    $process.CancelOutputRead()
    $process.CancelErrorRead()
    $process.Close()
  }
  return $exitCode
}


