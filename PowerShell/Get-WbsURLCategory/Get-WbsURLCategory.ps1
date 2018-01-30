<#
.SYNOPSIS
- Получение категории интернет ресурса из БД фильтрующей службы Forcepoint (Websense).
- Проверка доступности интернет ресурса для конкретного пользователя и\или IP-адреса.

.DESCRIPTION
Скрипт позволяет узнать категорию, определенную для ресурса в БД фильтрующей службы Forcepoint (Websense),
и\или результат фильтрации для конкретного пользователя (логин и\или ip) и ресурса.

При запуспе с параметрами -user и\или -userip, предоставляет дополнительную информацицию в виде:
    - Перечень AD групп пользователя, предоставляющих доступ в интернет (поиск по AD в соответсвии с фильтром, см. ниже).
    - Перечень политик Forcepoint, примененных к данному запросу.

Для запуска необходимо наличие утилиты WebsensePing.exe и соответсвующих ей библиотек в подпапке WebsensePing в рабочей папке скрипта.
Для пролучения информации по логину пользователя, должен быть установлен PS модуль ActiveDirectory.

В теле скрипта возможно настроить следующие переменные:
    $defPolServer - Адрес сервера Forcepoint по умолчанию (используется, если не указан параметр -server)
    $defPolTimeout - Таймаут по умолчанию для ожидания ответа от фильтрующих служб (в секундах)
    $modeUsr - Тип запроса WebsensePing для получения данных о фильтрации для пользователя\ip
    $modeUrl - Тип запроса WebsensePing для получения данных о категории ресурса
    $allowedADDomains - Список используемых AD доменов (используется в процессе проверки корректности указания логина)
    $adGrpMasks - Список фильтров для поиска AD групп, представлен в формате "комментарий", "фильтр",
    комментарий используется в качестве загаловка для блока групп, найденых по соответсвующему фильтру в выводе скрипта.
    $pcPref - Список префиксов имен ПК со значениями таймаутов для них (например, nsk* - 60 сек), переопределяют значение $defPolTimeout
    Используется для автоматического увеличения таймаута на запрос Policy Server'а для ПК в определенном регионе.
    $pacURL - URL PAC (или wpad) файла. Если этот параметр задан и скрипт запущен с параметром -userip -
    будет выведен список прокси-серверов для этого запроса, полученный в результате работы PAC-файла, в порядке перебора их клиентом (1-2-3...).



Запуск без параметров вернет номер версии скрипта.

.PARAMETER url
URL адрес ресурса

.PARAMETER user
UPN пользователя (login@domain), часть после @ используется для указания домена пользователя.

.PARAMETER userip
IP-адрес клиента.

.PARAMETER server
IP-адрес или DNS-имя сервера с установленными фильтрующими службами Forcepoint (Websense).

.PARAMETER timeout
Таймаут (в секундах) запроса к фильтрующим службам, по умолчанию равен 5 секундам.

.EXAMPLE
Get-WbsURLCategory.ps1 -url http://ya.ru
Поиск категории для ресурса http://ya.ru в БД Forcepoint (Websense).

.EXAMPLE
Get-WbsURLCategory.ps1 -url http://ya.ru -user test@domain.local -userip 10.0.0.5
Результат применения политик для пользователя test в домене domain.local с ip-адресом 10.0.0.5,
при доступе к ресурсу http://ya.ru (CATEGORY_BLOCKED, CATEGORY_NOT_BLOCKED и т.д.),
а также список групп AD и политик Forcepoint.

.EXAMPLE
Get-WbsURLCategory.ps1 -url http://ya.ru -server 10.1.0.100
Поиск категории для ресурса http://ya.ru в БД Forcepoint (Websense) на сервере 10.1.0.100

.NOTES
File Name       : Get-WbsURLCategory.ps1
Prerequisite    : PowerShell V2, WebsensePing.exe, pactester.exe, 64bit OS, ActiveDirectory PS module
Author          : Alexander V Borisov
Copyright       : 2018/B&N Bank

.LINK
https://www.binbank.ru
https://www.forcepoint.com/
http://findproxyforurl.com/
#>
Param (
    [Parameter(Position=0, Mandatory = $false)][string]$url,
    [Parameter(Position=1, Mandatory = $false)][Alias("username","login","upn")][string]$user,
    [Parameter(Position=2, Mandatory = $false)][Alias("ip","ipaddress")][string]$userip,
    [Parameter(Position=3, Mandatory = $false)][Alias("s")][string]$server,
    [Parameter(Position=4, Mandatory = $false)][Alias("t")][string]$timeout
)

# ---------------- Some basic settings here ----------------- #
# --------------- Некоторые базовые настройки --------------- #

$defPolServer = "10.0.0.1"
$defPolTimeout = "5"
$modeUsr = "27"
$modeUrl = "25"
$allowedADDomains = @("contoso.com")
$adGrpMasks = @(
    @("Группы доступа пользователя - Forcepoint","*.InternetAccess.Forcepoint.*"),
    @("Группы доступа пользователя - TMG","*.InternetAccess.TMG.*")
)
$pcPref = @{
    "nsk"="60"
}
$pacURL = "http://wbs-pac.corp.icba.biz/proxy.pac"

# ------ Please do not change anything below this line ------ #
# ------ Пожалуйста, не меняйте ничего ниже этой линии ------ #

$ver = "20180124.3"

$curDir = $MyInvocation.MyCommand.Definition | Split-Path -Parent
$pathWbsPing = ($curDir + "\WebsensePing\WebsensePing.exe")
if ([System.IntPtr]::Size -eq 4) {
    Write-Host -ForegroundColor Red "Работа в 32-битных ОС не поддерживается!"
    Exit
}
if (!(Get-Item $pathWbsPing -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "WebsensePing.exe не найден!"
    Exit
}
Try {&($pathWbsPing) | Out-Null}
Catch {Write-Host -ForegroundColor Red $_.Exception.Message; Exit}

$pathPacTester = ($curDir + "\PacTester\pactester.exe")
if (($pacURL -like "http*") -and !(Get-Item $pathPacTester -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "pactester.exe не найден!"
    Exit
}

$curPcPref = ($env:computername).Substring(0,3).ToLower()
if ($pcPref[$curPcPref]) {$defPolTimeout = $pcPref[$curPcPref]}
if ($timeout) {$polTimeout = $timeout}
else {$polTimeout = $defPolTimeout}

if (!$server) {$server = $defPolServer}

function Test-IPv4Address ($IPv4Address) {
    if ($IPv4Address.Split(".").Count -ne 4) {Write-Output $false; return}
    try {$chk = [ipaddress]$IPv4Address} catch {}
    if ($chk) {Write-Output $true} else {Write-Output $false}
}

function Test-UPN ($upn) {
    if ($upn.Split("@").Count -ne 2) {Write-Output $false; return}
    elseif ($allowedADDomains.Contains($upn.Split("@")[1].ToLower()) -eq $false) {Write-Output $false; return}
    else {Write-Output $true}
}

function GetProxyByPac ($cIP, $rURL, $pURL, $tstPath, $rndPath) {
    if ($rURL -notlike "http*") {$rURL = ("http://" + $rURL)}
    $rnd = Get-Random
    New-Item -ItemType File -Name ("Pac" + $rnd) -Path $rndPath -Value (Invoke-RestMethod -Method Get -Uri $pURL) | Out-Null
    $tResult = &($tstPath) -p ($rndPath + "\Pac" + $rnd) -c $cIP -u $rURL 2>&1
    Remove-Item -Path ($rndPath + "\Pac" + $rnd) -Force
    if (($tResult -like "PROXY *") -or ($tResult -eq "DIRECT")) {
        $tResult = $tResult.Split(";").Trim().Trim("PROXY").Trim()
    }
    else {
        $tResult = ""
    }
    Write-Output $tResult
}

if (!$url) {
    [string]$url = Read-Host -Prompt "Адрес (URL) ресурса (`"n`" для пропуска)"
    if ($url -eq "n") {$url = $null}
}
if (($url -and !$user) -or ($url -and (Test-UPN -upn $user) -ne $true)) {
    [string]$user = Read-Host -Prompt "Логин (UPN) пользователя (login@domain.local, `"n`" для пропуска)"
    if ($user -eq "n") {$user = $null}
    elseif ($user -and ((Test-UPN -upn $user) -ne $true)) {
        while ((Test-UPN -upn $user) -ne $true -and $user -ne "n") {[string]$user = Read-Host "Логин (UPN) пользователя (login@domain.local, `"n`" для пропуска)"}
        if ($user -eq "n") {$user = $null}
    }
}
if (($url -and !$userip) -or ($url -and (Test-IPv4Address -IPv4Address $userip) -ne $true)) {
    [string]$userip = Read-Host -Prompt "IP-адрес пользователя (x.x.x.x, `"n`" для пропуска)"
    if ($userip -eq "n") {$userip = $null}
    elseif ($userip -and ((Test-IPv4Address -IPv4Address $userip) -ne $true)) {
        while ((Test-IPv4Address -IPv4Address $userip) -ne $true -and $userip -ne "n") {[string]$userip = Read-Host "IP-адрес пользователя (x.x.x.x, `"n`" для пропуска)"}
        if ($userip -eq "n") {$userip = $null}
    }
}

if ($user -or $userip) {
    if ($user) {
        if (!(Get-Module -ListAvailable -Name ActiveDirectory)) {
            Write-Host -ForegroundColor Red "Не найден PowerShell модуль ActiveDirectory."
            Exit
        }
        Try {Import-Module ActiveDirectory}
        Catch {Write-Host -ForegroundColor Red $_.Exception.Message; Exit}
        Try {$adUser = Get-ADUser -Identity $user.Split("@")[0] -Properties MemberOf -Server $user.Split("@")[1]}
        Catch {Write-Host -ForegroundColor Red $_.Exception.Message; Exit}
        $adUserName = $adUser.Name
        $adUserUPN = $adUser.UserPrincipalName
        $adDomain = (Get-ADDomain -Identity $user.Split("@")[1] -Server $user.Split("@")[1]).NetBIOSName
        $adGrps = @()
        foreach ($rec in $adGrpMasks) {
            $adGrps += ,@($rec[0],$rec[1],,@($adUser.MemberOf | Get-ADGroup -Server $user.Split("@")[1] | Where-Object {$_.Name -like $rec[1]}).Name)
        }
        if ($userip) {
            Try {$RequestResult = &($pathWbsPing) -s $server -m  $modeUsr -url $url -uip $userip -user ("default://" + $adDomain + "\" + $adUser.SamAccountName) -t $polTimeout}
            Catch {Write-Host -ForegroundColor Red $_.Exception.Message; Exit}
            if ($pacURL -like "http*") {$uProxy = GetProxyByPac -cIP $userip -rURL $url -pURL $pacURL -tstPath $pathPacTester -rndPath $curDir}
        }
        else {
            Try {$RequestResult = &($pathWbsPing) -s $server -m  $modeUsr -url $url -user ("default://" + $adDomain + "\" + $adUser.SamAccountName) -t $polTimeout}
            Catch {Write-Host -ForegroundColor Red $_.Exception.Message; Exit}
            $userip = "-"
        }
    }
    elseif ($userip -and !$user) {
        Try {$RequestResult = &($pathWbsPing) -s $server -m  $modeUsr -url $url -uip $userip -user "WinNT://" -t $polTimeout}
        Catch {Write-Host -ForegroundColor Red $_.Exception.Message; Exit}
        $adUserName = "-"
        $adUserUPN = "-"
        if ($pacURL -like "http*") {$uProxy = GetProxyByPac -cIP $userip -rURL $url -pURL $pacURL -tstPath $pathPacTester -rndPath $curDir}
    }
    Try {$urlResp = ($RequestResult | Select-String -Pattern "URL = " -SimpleMatch).ToString().Split("=")[1].Trim()}
    Catch {Write-Host -ForegroundColor Red "Ошибка в разборе ответа WebsensePing (URL)"}
    Try {$ipDest = ($RequestResult | Select-String -Pattern "Destination IP = " -SimpleMatch).ToString().Split("=")[1].Trim()}
    Catch {Write-Host -ForegroundColor Red "Ошибка в разборе ответа WebsensePing (Destination IP)"}
    Try {$urlCat = ($RequestResult | Select-String -Pattern "Category = " -SimpleMatch).ToString().Split("=")[1].Trim()}
    Catch {Write-Host -ForegroundColor Red "Ошибка в разборе ответа WebsensePing (Category)"}
    Try {$urlDisp = ($RequestResult | Select-String -Pattern "Disposition = " -SimpleMatch).ToString().Split("=")[1].Trim()}
    Catch {Write-Host -ForegroundColor Red "Ошибка в разборе ответа WebsensePing (Disposition)"}
    Try {$wbsPol = ((($RequestResult | Select-String -Pattern "Policy Name = " -SimpleMatch).ToString().Split("=")[1].Trim()).Split(",")) | ForEach-Object {$_.Split("*")[2]}}
    Catch {Write-Host -ForegroundColor Red "Ошибка в разборе ответа WebsensePing (Policy Name)"}
    if ($urlDisp -like "*CATEGORY_BLOCKED*") {$color = "Red"}
    elseif ($urlDisp -like "*BLOCK_ALL*") {$color = "Red"}
    elseif ($urlDisp -like "*PROTOCOL_BLOCKED*") {$color = "Red"}
    elseif ($urlDisp -like "*BLOCKED_BY*") {$color = "Red"}
    elseif ($urlDisp -like "*CATEGORY_NOT_BLOCKED*") {$color = "Green"}
    elseif ($urlDisp -like "*PERMITTED_BY*") {$color = "Green"}
    else {$color = "Gray"}
    $outputInfo = ("`nПользователь:`n" + `
                   "`t" + $adUserName +  " (" + $adUserUPN + ")" + "`n" + `
                   "IP-адрес пользователя:`n" + `
                   "`t" + $userip + "`n")
    $outputResult = ("URL:`n" + `
                     "`t" + $urlResp + "`n" + `
                     "IP-адрес:`n" + `
                     "`t" + $ipDest + "`n" + `
                     "Категория:`n" + `
                     "`t" + $urlCat + "`n" + `
                     "Результат:`n" + `
                     "`t" + $urlDisp + "`n")
    Write-Host $outputInfo
    foreach ($rec in $adGrps) {
        if ($rec[2]) {
            Write-Host ($rec[0] + " (фильтр: " + $rec[1] + "):")
            $rec[2].Split("`n") | ForEach-Object {Write-Host "`t"$_}
            Write-Host ""
        }
    }
    if ($wbsPol.Count -ge 1) {
        Write-Host "Политики Forcepoint, примененные к этому запросу:"
        $wbsPol | ForEach-Object {Write-Host "`t"$_}
        Write-Host ""
    }
    if ($uProxy) {
        Write-Host "Результат выполнения PAC-файла для этого запроса (IP - URL):"
        $uProxy | ForEach-Object {$count=1}{Write-Host "`t [$count]"$_; $count++}
        Write-Host ""
    }
    Write-Host -ForegroundColor $color $outputResult
}
elseif ($url) {
    Try {$RequestResult = &($pathWbsPing) -s $server -m  $modeUrl -url $url -uip "10.0.0.0" -t $polTimeout}
    Catch {Write-Host -ForegroundColor Red $_.Exception.Message; Exit}
    Try {$urlResp = ($RequestResult | Select-String -Pattern "URL = " -SimpleMatch).ToString().Split("=")[1].Trim()}
    Catch {Write-Host -ForegroundColor Red "Ошибка в разборе ответа WebsensePing (URL)"}
    Try {$ipDest = ($RequestResult | Select-String -Pattern "Destination IP = " -SimpleMatch).ToString().Split("=")[1].Trim()}
    Catch {Write-Host -ForegroundColor Red "Ошибка в разборе ответа WebsensePing (Destination IP)"}
    Try {$urlCat = ($RequestResult | Select-String -Pattern "Categories = " -SimpleMatch).ToString().Split("=")[1].Trim()}
    Catch {Write-Host -ForegroundColor Red "Ошибка в разборе ответа WebsensePing (Category)"}
    $output = ("`nURL:`n" + `
               "`t" + $urlResp + "`n" + `
               "IP-адрес:`n" + `
               "`t" + $ipDest + "`n" + `
               "Категория:`n" + `
               "`t" + $urlCat + "`n")
    Write-Host $output
}
else {
    Write-Host "Версия:" $ver
    Exit
}