function which
{
$c=[Array](Get-Command $args[0] -ea 0)
if($null -eq $c){exit 1}
write-host $c[0].Definition
exit 0
}
function test([Switch]$o,[String]$p)
{
if(Test-Path $p){exit 0}
exit 1
}
function chmod{exit 0}
function chown{exit 0}
function mkdir([Switch]$o,[String]$p){if(Test-Path $p){exit 0}else{New-Item $p -Type Directory -Force | Out-Null}}
