Param(
  [Parameter(Mandatory=$true, POsition=1)]
  [string]$imageName,
  [Parameter(Mandatory=$true, POsition=2)]
  [string]$isoOrWim,  
    [Parameter(Mandatory=$false, POsition=3)]
  [string]$edition = "ServerDataCenter",  
    [Parameter(Mandatory=$true, POsition=4)]
  [string]$productKey,  

    [Parameter(Mandatory=$true, POsition=5)]
  [string]$companyName,  

    [Parameter(Mandatory=$true, POsition=6)]
  [string]$administratorPassword,

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


$isoFileName =  [System.IO.Path]::GetFileName($isoOrWim)
$isoDir = Join-Path $workDir $isoDirName
$isoFile = Join-Path $isoDir $isoFileName
$imagesDir = Join-Path $workDir $imagesDirName
$vhdName = Join-Path $imagesDir "$imageName.vhdx" 
$tempDir = join-path $workDir $tempDirName
$scriptsDir = Join-Path $workDir $scriptsDirName
CopyBigFile -source $isoOrWim -destination $isoFile

$templateFile = join-path (join-path $workDir $scriptsDirName) "unattend-template.xml"

$xml = [xml](OpenUnattend $templateFile)

$key = $productKey
$orgName = $companyName

$encodedPWD =  [System.Convert]::ToBase64String(([System.Text.Encoding]::Unicode.GetBytes($administratorPassword)))
write-host $encodedPWD

SetValue -selector "//u:settings[@pass='windowsPE']//u:ProductKey/u:Key" -value $key -xml $xml
SetValue -selector "//u:settings[@pass='specialize']//u:ProductKey" -value $key -xml $xml

SetValue -selector "//u:settings[@pass='windowsPE']//u:FullName" -value $orgName -xml $xml
SetValue -selector "//u:settings[@pass='windowsPE']//u:Organization" -value $orgName -xml $xml

SetValue -selector "//u:RegisteredOrganization" -value $orgName -xml $xml
SetValue -selector "//u:RegisteredOwner" -value $orgName -xml $xml


SetValue -selector "//u:settings[@pass='oobeSystem']//u:AdministratorPassword/u:Value" -value $encodedPWD -xml $xml

$targetUnattend = join-path $tempDir "unattend-$imageName.xml"


SaveUnattend -xml $xml -file $targetUnattend

. (join-path $scriptsDir "Convert-WindowsImage.ps1")

convert-windowsimage -SourcePath $isoFile -VHDPath $vhdName -SizeBytes 120GB  -Edition $edition -UnattendPath $targetUnattend -RemoteDesktopEnable 