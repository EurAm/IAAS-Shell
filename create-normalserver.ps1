Param(
  [Parameter(Mandatory=$true, POsition=1)]
  [string]$serverName,
  [Parameter(Mandatory=$true, POsition=2)]
  [string]$targetPath,  
  
  [switch]$base,
  [string]$basePath
)
$ErrorActionPreference = "Stop"
Import-Module ./common.psm1


if ($base -and   [string]::IsNullOrEmpty($basePath )){

Throw "If base is specified, basepath is required"

}








$path = "$targetPath\$serverName"

write-host "Creating $($path)"

New-Item $path -ItemType Directory

if (-not $base) {
write-host "Creating boot hard drive";

Copy-Item -Path ".\VHDs\normal.vhdx" -Destination "$path\base.vhdx"
New-VHD -Path "$path\boot.vhdx" -Differencing -ParentPath "$path\base.vhdx" -SizeBytes 120GB
}
else {
    if (-not (Test-Path $basePath)) {
        Copy-Item -Path ".\VHDs\normal.vhdx" -Destination "$basePath"    
    }
    New-VHD -Path "$path\boot.vhdx" -Differencing -ParentPath $basePath -SizeBytes 120GB
}

write-host "Setting host name";
$driveLetter = (Mount-VHD -Path "$path\boot.vhdx" -Passthru | get-disk -number {$_.DiskNumber} | Get-Partition | Get-Volume).DriveLetter

patchUnattended ("{0}:\unattend.xml" -F $driveLetter)

write-host "Injecting script";

$cpath = ("{0}:\Windows\Setup\Scripts" -F $driveLetter)

write-host "Injecting script into $cpath";
New-Item $cpath -ItemType Directory 


$content = [System.IO.File]::ReadAllText("Z:\normal.cmd").Replace("%HOSTNAME%", $serverName)
[System.IO.File]::WriteAllText("$cpath\SetupComplete.cmd", $content)

$tools = ("{0}:\Tools" -F $driveLetter)
write-host "Copying tools to $tools";
New-Item $tools -ItemType Directory 
Copy-Item -path Z:\tools\* -Destination $tools



Dismount-VHD "$path\boot.vhdx"

write-host "Creating and configuring virtual machine";
New-VM -Name $serverName -MemoryStartupBytes 1GB -Generation 2 -ComputerName HVH1 -VHDPath "$path\boot.vhdx"  -Path "$path\VM"

Set-VM -Name $serverName -ComputerName HVH1 -DynamicMemory -MemoryMaximumBytes 12GB
Set-VMProcessor -VMName $serverName -ComputerName HVH1 -Count 4
Connect-VMNetworkAdapter -VMName $serverName -SwitchName Public
Set-VMNetworkAdapterVlan -VMName $serverName -Access -VlanId 102

write-host "Making it highly available";
Add-ClusterVirtualMachineRole -VirtualMachine $serverName -Name $serverName

write-host "Starting vm $servername";
Start-VM -Name $serverName
