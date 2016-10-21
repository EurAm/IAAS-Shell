Param(
  [string]$serverName  ,
  [string]$targetPath
)

$path = "$targetPath\$serverName"


Remove-ClusterGroup -VMId (Get-VM -Name $serverName).VMId -RemoveResources

Stop-VM -Force -Name $serverName
Remove-VM -Force -Name $serverName
Remove-Item -Recurse $path