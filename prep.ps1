If ((Get-Module "common").Count -gt 0) {
    Remove-Module "common"
}
Import-Module ./common.psm1

$xml = [xml](OpenUnattend "Unattend.xml")

$key = "******KEY HERE******"
$orgName = "***** ORG HERE ****"
$adminPWD = "TEST"
$encodedPWD =  [System.Convert]::ToBase64String(([System.Text.Encoding]::Unicode.GetBytes($adminPWD)))
$computerName = "****COMPUTER NAME HERE*****"

SetValue -selector "//u:settings[@pass='windowsPE']//u:ProductKey/u:Key" -value $key -xml $xml
SetValue -selector "//u:settings[@pass='specialize']//u:ProductKey" -value $key -xml $xml

SetValue -selector "//u:settings[@pass='windowsPE']//u:FullName" -value $orgName -xml $xml
SetValue -selector "//u:settings[@pass='windowsPE']//u:Organization" -value $orgName -xml $xml

SetValue -selector "//u:RegisteredOrganization" -value $orgName -xml $xml
SetValue -selector "//u:RegisteredOwner" -value $orgName -xml $xml


SetValue -selector "//u:settings[@pass='oobeSystem']//u:AdministratorPassword/u:Value" -value $encodedPWD -xml $xml

SetValue -selector "//u:ComputerName" -value $orgName -xml $xml

SaveUnattend -xml $xml -file "unattend2.xml"