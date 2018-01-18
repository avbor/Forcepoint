
Param (
    [Parameter(Position=0, Mandatory = $false)]$Source = "C:\Program Files\Websense\Web Security\bin",
    [Parameter(Position=1, Mandatory = $false)]$Destination = ".\WebsensePing"
)

if (!(Test-Path $Source)) {
    Write-Host -ForegroundColor Red "Путь" $Source "не найден!"
    Exit
}

$WbsPngFiles = @(
    "btrow42.dll",
    "btuc42.dll",
    "diagnostics.cfg",
    "Diagnostics.dll",
    "fpblowfish.dll",
    "libcurl.dll",
    "libeay32.dll",
    "log4cxx.dll",
    "msvcp110.dll",
    "msvcr110.dll",
    "ssleay32.dll",
    "WebsensePing.exe",
    "WFCBase.dll",
    "WFCCrypto.dll",
    "WFCNetwork.dll",
    "WFCRoot.dll"
)

function CheckSource ($flieList, $fld) {
    $notFound = @()
    $found = @()
    foreach ($file in $flieList) {
        $chk = Get-ChildItem -Path $fld -Name $file -ErrorAction SilentlyContinue
        if (!$chk) {$notFound += $file}
        else {$found += ($fld.Trim("\") + "\" + $file)}
    }
    $output = @{"Found"=$found; "NotFound"=$notFound}
    Write-Output $output
}

$srcChk = CheckSource -flieList $WbsPngFiles -fld $Source

if ($srcChk["NotFound"]) {
    Write-Host "В исходной папке отсутсвуют файлы:"
    Write-Host $srcChk["NotFound"]
}
elseif ($srcChk["Found"]) {
    if (!(Test-Path $Destination)) {New-Item -ItemType Directory -Path $Destination | Out-Null}
    $srcChk["Found"] | ForEach-Object {Copy-Item -Path $_ -Destination $Destination -Force}
    Write-Host -ForegroundColor Green "Необходимые файлы скопированы в папку" (Get-Item $Destination).FullName
}