# Get-WbsApl-HotfixInfo.ps1

$baseUri = "http://appliancehotfix.websense.com/download/hotfixes/index.json"

$getBase = Invoke-RestMethod -Method Get -Uri $baseUri
$allUri = $getBase.PSObject.Properties | ForEach-Object {$_.Value}
$aVers = (($getBase.PSObject.Properties | ForEach-Object {$_.value.PSObject.Properties} | Select-Object Name -Unique).Name) | Sort-Object
$hfs = @()
$App = @()
$Web = @()
$Proxy = @()
$Email = @()
$Other = @()

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

foreach ($uri in $allUri.$ver) {
    if ($uri) {$hfs += Invoke-RestMethod -Method Get -Uri $uri}
}

foreach ($hf in $hfs) {
    if ($hf.id -like "App-*") {$App += $hf}
    elseif ($hf.id -like "Web-*") {$Web += $hf}
    elseif ($hf.id -like "Proxy-*") {$Proxy += $hf}
    elseif ($hf.id -like "Email-*") {$Email += $hf}
    else {$Other += $hf}
}

function PrintHFInfo ($fix) {
    Write-Host -ForegroundColor Green $fix.id
    Write-Host -ForegroundColor White $fix.description
    if ($hf.url) {Write-Host "Download:" $fix.url}
    if ($hf.release_note_url) {Write-Host "Release notes:" $fix.release_note_url}
    Write-Host
}

Write-Host "`nAvailable hotfixes for version $ver"

if ($App) {
    Write-Host -ForegroundColor Yellow "`nFor Appliance:`n"
    foreach ($hf in $App) {
        PrintHFInfo -fix $hf
    }
}
if ($Web) {
    Write-Host -ForegroundColor Yellow "`nFor Filtering Services:`n"
    foreach ($hf in $Web) {
        PrintHFInfo -fix $hf
    }
}
if ($Proxy) {
    Write-Host -ForegroundColor Yellow "`nFor Content Gateway:`n"
    foreach ($hf in $Proxy) {
        PrintHFInfo -fix $hf
    }
}
if ($Email) {
    Write-Host -ForegroundColor Yellow "`nFor Email Security Gateway:`n"
    foreach ($hf in $Email) {
        PrintHFInfo -fix $hf
    }
}
if ($Other) {
    Write-Host -ForegroundColor Yellow "`nFor Other components:`n"
    foreach ($hf in $Other) {
        PrintHFInfo -fix $hf
    }
}