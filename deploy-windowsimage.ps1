Param(
  [Parameter(Mandatory=$true, POsition=1)]
  [string]$serverName,
  [Parameter(Mandatory=$true, POsition=2)]
  [string]$imageName,    
    [Parameter(Mandatory=$true, POsition=3)]
  [string]$targetPath,
  [string]$basePath,
    [string]$workDir = (get-location),
    [string]$installScriptName = "normal",

    [switch]$makeHA ,
    [string]$targetHost = "$env:computername.$env:userdnsdomain",
    [string]$switchName ="public",
    [int]$vlanId = 0
   
)
$ErrorActionPreference = "Stop"

 $isoDirName = "ISO"
$imagesDirName = "VHDs"
$scriptsDirName = "Scripts"
$tempDirName = "Temp"
$toolsDirName = "Tools"


If ((Get-Module "common").Count -gt 0) {
    Remove-Module "common"
}

Import-Module ./common.psm1

$currentDirName = [System.IO.Path]::GetFileName($workDir)
if ($currentDirName -ieq "Scripts"){
    $workDir = [System.IO.Path]::GetDirectoryName($workDir)
}

$base = -not [string]::IsNullOrEmpty($basePath )




$imagesDir = Join-Path $workDir $imagesDirName

$sourceVhd = Join-Path $imagesDir "$imageName.vhdx"


$path = join-path $targetPath $serverName
$bootVhd = join-path $path "boot.vhdx"
write-host "Creating $($path)"

TryCreateDir $path

if (-not $base) {
    Write-Host "Creating boot hard drive";

    CopyBigFile -source $sourceVhd -destination (Join-Path $path "base.vhdx")
    New-VHD -Path $bootVhd -Differencing -ParentPath (Join-Path $path "base.vhdx") -SizeBytes 120GB
}
else {
    if (-not (Test-Path $basePath)) {
        CopyBigFile -source $sourceVhd -Destination $basePath
    }
    if (Test-Path $bootVhd) { Remove-Item $bootVhd }
    New-VHD -Path $bootVhd -Differencing -ParentPath $basePath -SizeBytes 120GB
}

write-host "mounting vhd"
$driveLetter = (Mount-VHD -Path $bootVhd -Passthru | Get-Disk -number {$_.DiskNumber} | Get-Partition | Get-Volume).DriveLetter
write-host "vhd mounted at $driveLetter"
write-host "Setting host name";
$unattendFile = ("{0}:\unattend.xml" -F $driveLetter)

#set host name
$xml = [xml](OpenUnattend $unattendFile)

SetValue -selector "//u:ComputerName" -value $serverName -xml $xml

SaveUnattend -xml $xml -file $unattendFile



write-host "Injecting script";

$cpath = ("{0}:\Windows\Setup\Scripts" -F $driveLetter)

write-host "Injecting script into $cpath";
New-Item $cpath -ItemType Directory 

$scriptFile = Join-Path $workDir "$scriptsDirName\InstallScripts\$installScriptName.cmd"

$content = [System.IO.File]::ReadAllText($scriptFile).Replace("%HOSTNAME%", $serverName)
[System.IO.File]::WriteAllText("$cpath\SetupComplete.cmd", $content)

$tools = ("{0}:\Tools" -F $driveLetter)
write-host "Copying tools to $tools";
TryCreateDir $tools
Copy-Item -path (join-path $workDir $toolsDirName) -Recurse  -Destination $tools



Dismount-VHD $bootVhd

write-host "Creating and configuring virtual machine";
New-VM -Name $serverName -MemoryStartupBytes 1GB -Generation 2 -ComputerName $targetHost -VHDPath $bootVHD  -Path "$path\VM"

Set-VM -Name $serverName -ComputerName $targetHost -DynamicMemory -MemoryMaximumBytes 12GB
Set-VMProcessor -VMName $serverName -ComputerName $targetHost -Count 4
Connect-VMNetworkAdapter -VMName $serverName -SwitchName $switchName
if ($vlanId -gt 0){
    Set-VMNetworkAdapterVlan -VMName $serverName -Access -VlanId $vlanId
}

if ($makeHA) {
    write-host "Making it highly available";
    Add-ClusterVirtualMachineRole -VirtualMachine $serverName -Name $serverName
}
write-host "Starting vm $servername";
Start-VM -Name $serverName
