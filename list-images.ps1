Param(
    [string]$workDir = (get-location)   
)
If ((Get-Module "common").Count -gt 0) {
    Remove-Module "common"
}

Import-Module ./common.psm1

$currentDirName = [System.IO.Path]::GetFileName($workDir)
if ($currentDirName -ieq "Scripts"){
    $workDir = [System.IO.Path]::GetDirectoryName($workDir)
}


$imagesDirName = "VHDs"

Get-ChildItem (Join-Path $workDir $imagesDirName) | Select-Object -Property BaseName 