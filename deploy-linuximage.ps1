Param(
  [Parameter(Mandatory=$true, POsition=1)]
  [string]$serverName,
  [Parameter(Mandatory=$true, POsition=2)]
  [string]$imageName,    
    [Parameter(Mandatory=$true, POsition=3)]
  [string]$targetPath,
  [string]$basePath,
    [string]$workDir = (get-location),
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



write-host "Creating and configuring virtual machine";
New-VM -Name $serverName -MemoryStartupBytes 1GB -Generation 1 -ComputerName $targetHost -VHDPath $bootVHD  -Path "$path\VM"

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
