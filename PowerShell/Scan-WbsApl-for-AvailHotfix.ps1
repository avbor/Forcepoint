<#
.SYNOPSIS
Scanning apliances for available hotfixes

.DESCRIPTION
Scanning apliances for available hotfixes
Tested on Forcepoint v8.4 and above

.PARAMETER Password
Password for default user "admin"

.PARAMETER Aplainces
List of appliances to scan

.EXAMPLE
.\Scan-WbsApl-for-AvailHotfix.ps1 -Password P@ssw0rd! -Aplainces "appliance01","appliance02","appliance03"

.NOTES
Alexander V Borisov
B&N Bank 2018

.LINK
http://www.binbank.ru
#>

Param (
    [Parameter(Position=0,Mandatory=$false)]$Aplainces=@(),
    [Parameter(Position=0,Mandatory = $false)]$Password
)

$pathToInvokeWbsAPIRequest = "D:\Develop\powershell\Websense\Invoke-WbsAPI-Request.ps1"
if (!(Get-Item $pathToInvokeWbsAPIRequest -ErrorAction SilentlyContinue)) {
    $pathToInvokeWbsAPIRequest = Read-Host "Path to Invoke-WbsAPI-Request.ps1"
}

$adm = "admin"
if ($Password) {$admpass = $Password}
else {
    $secpass = Read-Host "Password for `"admin`" user" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secpass)
    $admpass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

foreach ($apl in $Aplainces) {
    Write-Output ($apl + ":")
    $err = $false
    $count = 1
    while ($count -le 3) {
        $res = $null
        try {
            $res = Invoke-Expression (
                    $pathToInvokeWbsAPIRequest + " -user " + $adm + `
                    " -pass " + $admpass + `
                    " -method GET -url " + "https://" + $apl + "/api/app/v1/hotfix/list"
                )
            $err = $false
        }
        catch {
            $err = $true
            Write-Output ("`t" + $_.Exception.Message)
            Start-Sleep -Seconds 1
        }
        if ($err) {$count++; continue}
        else {break}
    }
    if ($res) {
        foreach ($hf in $res.list) {
            Write-Output ("`t" + $hf.id + " (" + $hf.description + ")")
        }
    }
    else {Write-Output "`tNothing found..."}
}