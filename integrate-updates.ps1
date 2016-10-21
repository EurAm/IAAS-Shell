Param(
  [Parameter(Mandatory=$true, POsition=1)]
  [string]$vhdFile,
  [Parameter(Mandatory=$true, POsition=2)]
  [string]$patchpath  
)

$driveLetter = (Mount-VHD -Path $vhdFile -Passthru | get-disk -number {$_.DiskNumber} | Get-Partition | Get-Volume).DriveLetter
$updatePath = $driveLetter +":\"


$updates = get-childitem -path $patchpath -Recurse | where {($_.extension -eq ".msu") -or ($_.extension -eq ".cab")} | select fullname

try {
       $i = 0
        foreach($update in $updates)
        {
            $i++
            write-debug $update.fullname
            $command = "dism /image:" + $updatepath + " /add-package /packagepath:'" + $update.fullname + "'"
            write-debug $command
            Invoke-Expression $command
            write-host "Installed update " + $update.fullname + ". This is update $i of " + $updates.length
        }
}

Finally {
    dismount-vhd -path $vhdFile
}