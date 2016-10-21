Param(
  [Parameter(Mandatory=$true, POsition=1)]
  [string]$imageName,

  [Parameter(Mandatory=$true, POsition=2)]
  [string]$vhdFile,
  [string]$workDir = (get-location)
  
 )  

 $isoDirName = "ISO"
$imagesDirName = "VHDs"
$scriptsDirName = "Scripts"
$tempDirName = "Temp"

If ((Get-Module "common").Count -gt 0) {
    Remove-Module "common"
}

Import-Module ./common.psm1

$currentDirName = [System.IO.Path]::GetFileName($workDir)
if ($currentDirName -ieq "Scripts"){
    $workDir = [System.IO.Path]::GetDirectoryName($workDir)
}


$imagesDir = Join-Path $workDir $imagesDirName
$vhdName = Join-Path $imagesDir "$imageName.vhdx" 

CopyBigFile -source $vhdFile -destination $vhdName