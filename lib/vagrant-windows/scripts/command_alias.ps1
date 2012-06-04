function which {
    $command = [Array](Get-Command $args[0] -errorAction continue)
    write-host  $command[0].Definition
}

function test ([Switch] $d, [String] $path) {
  Resolve-Path $path| Out-Null;
}

function chown {
  exit 0
}

function mkdir ([Switch] $p, [String] $path)
{
  if(Test-Path $path)
  {
    exit 0
  } else {
    New-Item $p -Type Directory -Force | Out-Null
  }
}

