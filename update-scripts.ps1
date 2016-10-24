Param(
    [string]$workDir = (get-location)   ,
    [string]$source = "https://github.com/EurAm/IAAS-Shell/archive/master.zip"
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
$scriptsDirName = "Scripts"
$tempDirName = "Temp"

$tempDir = Join-Path $workDir $tempDirName
$scriptsDir = Join-Path $workDir $scriptsDirName
$zip = Join-Path $tempDir "master.zip"
if (Test-Path $zip) {
     Remove-Item $zip
}
DownloadFile $source $zip
$now = [System.DateTime]::Now.ToString().Replace(":", "").Replace("/","")
$tempunpackdir = Join-Path $tempDir $now
TryCreateDir $tempunpackdir
[System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
[System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $tempunpackdir)
$cdir =  (Get-ChildItem $tempunpackdir).Name
cp (Join-Path $tempunpackdir "$cdir\*") $scriptsDir -Recurse -Force -Exclude InstallScripts