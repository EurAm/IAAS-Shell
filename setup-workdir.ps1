Param(
  [Parameter(Mandatory=$true, POsition=1)]
  [string]$workDir
)
Import-Module ./common.psm1

$isoDirName = "ISO"
$imagesDirName = "VHDs"
$scriptsDirName = "Scripts"
$tempDirName = "Temp"
$updatesDirName = "Updates"
$toolsDirName = "Tools"

$dirNames = ($isoDirName, $imagesDirName, $scriptsDirName, $tempDirName, $updatesDirName, $toolsDirName)



TryCreateDir($workDir)

foreach($dir in $dirNames) {
    $fullPath = Join-Path $workDir $dir
    tryCreateDir($fullPath)
}




$scriptsDir = Join-Path $workDir $scriptsDirName
Copy-Item -Recurse -Force -Path "./*" -Destination $scriptsDir -Exclude ".git"
