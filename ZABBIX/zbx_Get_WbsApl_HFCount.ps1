# zbx_Get_WbsApl_HFCount.ps1

Param (
    [Parameter(Mandatory = $false)]$version="8.4.0",
    [Parameter(Mandatory = $false)]$proxy,
    [Parameter(Mandatory = $false)][switch]$all,
    [Parameter(Mandatory = $false)][switch]$web,
    [Parameter(Mandatory = $false)][switch]$wcg,
    [Parameter(Mandatory = $false)][switch]$email,
    [Parameter(Mandatory = $false)][switch]$apl,
    [Parameter(Mandatory = $false)][switch]$other
)

$baseUri = "http://appliancehotfix.websense.com/download/hotfixes/index.json"

$OpProxy = @{}
if ($proxy) {
    $OpProxy['Proxy'] = $proxy
}

$baseData = Invoke-RestMethod -Method Get -Uri $baseUri @OpProxy

if ($all) {
    $uriAll = ($baseData.PSObject.Properties | ForEach-Object {$_.Value}).$version
    $hfs = @()
    foreach ($uri in $uriAll) {
        if ($uri) {$hfs += Invoke-RestMethod -Method Get -Uri $uri @OpProxy}
    }
    Write-Output $hfs.Count
}
elseif ($web) {
    if ($baseData.web.$version) {
        $hfs = Invoke-RestMethod -Method Get -Uri $baseData.web.$version @OpProxy
        Write-Output $hfs.Count
    
    }
    else {Write-Output 0}
}
elseif ($wcg) {
    if ($baseData.proxy.$version) {
        $hfs = Invoke-RestMethod -Method Get -Uri $baseData.proxy.$version @OpProxy
        Write-Output $hfs.Count
    }
    else {Write-Output 0}
}
elseif ($email) {
    if ($baseData.email.$version) {
        $hfs = Invoke-RestMethod -Method Get -Uri $baseData.email.$version @OpProxy
        Write-Output $hfs.Count
    }
    else {Write-Output 0}
}
elseif ($apl) {
    if ($baseData.app.$version) {
        $hfs = Invoke-RestMethod -Method Get -Uri $baseData.app.$version @OpProxy
        Write-Output $hfs.Count
    }
    else {Write-Output 0}
}
elseif ($other) {
    if ($baseData.na.$version) {
        $hfs = Invoke-RestMethod -Method Get -Uri $baseData.na.$version @OpProxy
        Write-Output $hfs.Count
    }
    else {Write-Output 0}
}