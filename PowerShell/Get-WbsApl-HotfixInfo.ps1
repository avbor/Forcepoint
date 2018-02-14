# Get-WbsApl-HotfixInfo.ps1

Param (
    [Parameter(Position=0, Mandatory = $false)][string]$Version,
    [Parameter(Position=1, Mandatory = $false)][string]$Proxy
)

$baseUri = "http://appliancehotfix.websense.com/download/hotfixes/index.json"

$OpProxy = @{}
if ($proxy) {
    while ($proxy -notlike "http*") {
        $proxy = Read-Host "Proxy address (http://proxy:8080)"
    }
    $OpProxy['Proxy'] = $proxy
}

try {$getBase = Invoke-RestMethod -Method Get -Uri $baseUri -Headers @{"Cache-Control"="no-cache"} @OpProxy}
catch {Write-Host $_.Exception.Message; Exit}
$allUri = $getBase.PSObject.Properties | ForEach-Object {$_.Value}
$aVers = (($getBase.PSObject.Properties | ForEach-Object {$_.value.PSObject.Properties} | Select-Object Name -Unique).Name) | Sort-Object
$hfs = @()
$App = @()
$Web = @()
$Wcg = @()
$Email = @()
$Other = @()

if (!$Version) {
    Write-Host "`nPlease, choise Forcepoint solution version:`n"
    $aVers | ForEach-Object {$count=1}{
        if ($aVers.Count -eq $count) {Write-Host -ForegroundColor Yellow "[$count] - $_`n"}
        else {Write-Host -ForegroundColor White "[$count] - $_"}
        $count++
    }
    $lastVer = $aVers.Count
    $userChoice = Read-Host "Default [$lastVer]"
    if (!$userChoice) {$ver = $aVers[$lastVer-1]}
    else {$ver = $aVers[$userChoice-1]}
}
else {
    $ver = $Version
}

foreach ($uri in $allUri.$ver) {
    if ($uri) {
        try {$hfs += Invoke-RestMethod -Method Get -Uri $uri -Headers @{"Cache-Control"="no-cache"} @OpProxy}
        catch {Write-Host $_.Exception.Message; Exit}
    }
}

foreach ($hf in $hfs) {
    if ($hf.module -eq "app") {$App += $hf}
    elseif ($hf.module -eq "web") {$Web += $hf}
    elseif ($hf.module -eq "proxy") {$Wcg += $hf}
    elseif ($hf.module -eq "email") {$Email += $hf}
    else {$Other += $hf}
    $hf = $null
}

function PrintHFInfo ($fix) {
    Write-Host -ForegroundColor Green $fix.id
    Write-Host -ForegroundColor White $fix.description
    if ($fix.url) {Write-Host "Download:" $fix.url}
    if ($fix.release_note_url) {Write-Host "Release notes:" $fix.release_note_url}
    Write-Host
}

Write-Host "`nAvailable hotfixes for version $ver"

if ($App) {
    Write-Host -ForegroundColor Yellow "`nFor Appliance ["$App.Count"]:`n" -Separator ""
    foreach ($hf in $App) {
        PrintHFInfo -fix $hf
    }
    $hf = $null
}
if ($Web) {
    Write-Host -ForegroundColor Yellow "`nFor Filtering Services ["$Web.Count"]:`n" -Separator ""
    foreach ($hf in $Web) {
        PrintHFInfo -fix $hf
    }
    $hf = $null
}
if ($Wcg) {
    Write-Host -ForegroundColor Yellow "`nFor Content Gateway ["$Wcg.Count"]:`n" -Separator ""
    foreach ($hf in $Wcg) {
        PrintHFInfo -fix $hf
    }
    $hf = $null
}
if ($Email) {
    Write-Host -ForegroundColor Yellow "`nFor Email Security Gateway ["$Email.Count"]:`n" -Separator ""
    foreach ($hf in $Email) {
        PrintHFInfo -fix $hf
    }
    $hf = $null
}
if ($Other) {
    Write-Host -ForegroundColor Yellow "`nFor Other components ["$Other.Count"]:`n" -Separator ""
    foreach ($hf in $Other) {
        PrintHFInfo -fix $hf
    }
    $hf = $null
}