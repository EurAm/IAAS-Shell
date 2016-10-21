

function TryCreateDir($path) {
    $pathExists = Test-Path $path
    if ($pathExists -eq $false) {
        New-Item -Path $path -ItemType Directory
    }
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

function OpenUnattend([string]$file) {
    $xml = [xml](Get-Content  $file )



    return $xml
}
 
function SetValue([xml]$xml, [string]$selector, $value){
    [System.Xml.XmlNamespaceManager] $nsm = $xml.NameTable
    $nsm.AddNamespace("u", "urn:schemas-microsoft-com:unattend")
    $xml.SelectNodes($selector, $nsm) | Foreach-Object {$_.InnerText = $value}
}

function SaveUnattend([xml]$xml,[string] $file) {
    $xml.Save($file)
}

function CopyBigFile([string]$source, [string]$destination) {
    $sourceFileName = [System.IO.Path]::GetFileName($source)

    if ((Test-Path $destination) -eq $false) {

        Write-Host "Copying $sourceFileName"
        Import-Module BitsTransfer
        Start-BitsTransfer -Source $source -Destination $destination -Description "Copying file $source" -DisplayName  "Copying files"
  
    } else {
        Write-Host "Skipping copy of $sourceFileName because file allready exists"
    }
}

function DownloadFile([string]$source, [string]$destination) {
    $sourceFileName = [System.IO.Path]::GetFileName($source)

    if ((Test-Path $destination) -eq $false) {

        Write-Host "Downloading $sourceFileName"
        Import-Module BitsTransfer
        Start-BitsTransfer -Source $source -Destination $destination -Description "Downloading $source" -DisplayName  "Downloading files"
  
    } else {
        Write-Host "Skipping download of $sourceFileName because file allready exists"
    }
}