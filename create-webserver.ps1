Param(
  [Parameter(Mandatory=$true, POsition=1)]
  [string]$serverName,
  [Parameter(Mandatory=$true, POsition=2)]
  [string]$targetPath,
  [Parameter(Mandatory=$true, POsition=3)]
  [string]$role,
  [switch]$base,
  [string]$basePath
)
$ErrorActionPreference = "Stop"


if ($base -and   [string]::IsNullOrEmpty($basePath )){

Throw "If base is specified, basepath is required"

}
 
function MountVHD ($VHDPath)
{
    Mount-VHD $VHDPath
    $drive = (Get-DiskImage -ImagePath $VHDPath | `
                 Get-Disk | `
                 Get-Partition).DriveLetter
    "$($drive):\"
    Get-PSDrive | Out-Null # Work around. some times the drive is not mounted
}
 
# Dismount an already mounted VHD file
# After dismount the drive is not accessible.
 
function DismountVHD ($VHDPath)
{
    Dismount-VHD $VHDPath
}
 

 
function CreateVHD ($VHDPath, $Size)
{
  $drive = (New-VHD -path $vhdpath -SizeBytes $size -Dynamic   | `
              Mount-VHD -Passthru |  `
              get-disk -number {$_.DiskNumber} | `
              Initialize-Disk -PartitionStyle GPT -PassThru | `
              New-Partition -UseMaximumSize -AssignDriveLetter:$False  | `
              Format-Volume -Confirm:$false -FileSystem NTFS -force | `
              get-partition | `
              Add-PartitionAccessPath -AssignDriveLetter -PassThru | `
              get-volume).DriveLetter
 
    Dismount-VHD $VHDPath
    
}

function patchUnattended($file){
$xml = [xml](Get-Content  $file )

[System.Xml.XmlNamespaceManager] $nsm = $xml.NameTable
$nsm.AddNamespace("df", "urn:schemas-microsoft-com:unattend")


$xml.SelectNodes("//df:ComputerName", $nsm) | Foreach-Object {$_.InnerText = $serverName}
#$xml.SelectNodes("//df:MachinePassword", $nsm) | Foreach-Object {$_.InnerText = $serverName.ToLowerInvariant()}

$xml.Save($file)

}




$path = "$targetPath\$serverName"

write-host "Creating $($path)"

New-Item $path -ItemType Directory

if (-not $base) {
write-host "Creating boot hard drive";

Copy-Item -Path ".\VHDs\webserverwupdates.vhdx" -Destination "$path\base-web.vhdx"
New-VHD -Path "$path\boot.vhdx" -Differencing -ParentPath "$path\base-web.vhdx" -SizeBytes 120GB
}
else {
    if (-not (Test-Path $basePath)) {
        Copy-Item -Path ".\VHDs\webserverwupdates.vhdx" -Destination "$basePath"    
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


$content = [System.IO.File]::ReadAllText("Z:\webserver.cmd").Replace("%HOSTNAME%", $serverName).Replace("%ROLE%", $role)
[System.IO.File]::WriteAllText("$cpath\SetupComplete.cmd", $content)

$tools = ("{0}:\Tools" -F $driveLetter)
write-host "Copying tools to $tools";
New-Item $tools -ItemType Directory 
Copy-Item -path Z:\tools\* -Destination $tools



Dismount-VHD "$path\boot.vhdx"



write-host "Creating data hard drive";
CreateVHD "$path\data.vhdx" 60GB


write-host "Creating and configuring virtual machine";
New-VM -Name $serverName -MemoryStartupBytes 1GB -Generation 2 -ComputerName HVH1 -VHDPath "$path\boot.vhdx"  -Path "$path\VM"
Add-VMHardDiskDrive -VMName $serverName -Path "$path\data.vhdx" -ControllerType SCSI -ComputerName HVH1
Set-VM -Name $serverName -ComputerName HVH1 -DynamicMemory -MemoryMaximumBytes 12GB
Set-VMProcessor -VMName $serverName -ComputerName HVH1 -Count 4
Connect-VMNetworkAdapter -VMName $serverName -SwitchName Public
Set-VMNetworkAdapterVlan -VMName $serverName -Access -VlanId 102

write-host "Making it highly available";
Add-ClusterVirtualMachineRole -VirtualMachine $serverName -Name $serverName

write-host "Starting vm $servername";
Start-VM -Name $serverName
