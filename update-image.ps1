Param(
  [Parameter(Mandatory=$true, POsition=1)]
  [string]$imageName,
  [string]$platform = "w63-x64",
  [string]$workDir = (get-location)
 )


$isoDirName = "ISO"
$imagesDirName = "VHDs"
$scriptsDirName = "Scripts"
$tempDirName = "Temp"
$updatesDirName = "Updates"

If ((Get-Module "common").Count -gt 0) {
    Remove-Module "common"
}

Import-Module ./common.psm1

$currentDirName = [System.IO.Path]::GetFileName($workDir)
if ($currentDirName -ieq "Scripts"){
    $workDir = [System.IO.Path]::GetDirectoryName($workDir)
}



$updatesDir = Join-Path $workDir $updatesDirName
$tempDir = Join-Path $workDir $tempDirName
$wsusofflineDir = Join-Path $updatesDir "wsusoffline"

if ((Test-Path $wsusofflineDir) -eq $false) {
    mkdir $wsusofflineDir 
    $wsusZip=(join-path $tempDir "wsus.zip")
    DownloadFile "http://download.wsusoffline.net/wsusoffline108.zip" $wsusZip

    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
    [System.IO.Compression.ZipFile]::ExtractToDirectory($wsusZip, $wsusofflineDir)  

}

$loc = Get-Location

cd (join-path $wsusofflineDir "wsusoffline\cmd")

.\DownloadUpdates.cmd $platform glb /proxy http://10.102.253.254:3128 

cd $loc

$updatesLocation = join-path $wsusofflineDir "wsusoffline\client\$platform\glb"

.(Join-Path $workDir "$scriptsDirName\integrate-updates.ps1") -vhdfile (Join-Path $workDir "$imagesDirName\$imageName.vhdx") -patchpath $updatesLocation

