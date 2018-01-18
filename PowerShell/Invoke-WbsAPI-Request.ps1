<#
.SYNOPSIS
Работа с RESTful API Forcepoint Appliances из Windows окружения

.DESCRIPTION
Скрипт позволяет выполнять обращения к RESTful API Forcepoint Appliances из Windows окружения
Является своего рода оберткой для стандартного командлета Invoke-RestMethod
Позволяет обойти проблемы с HTTP Basic авторизацией и SelfSigned сертификатами у Invoke-RestMethod

Работа протестирована на Forcepoint Virtual Appliance 8.4

.PARAMETER user
локальный пользователь аплаинса с административными привелегиями (обычно admin)

.PARAMETER pass
Пароль пользователя

.PARAMETER method
HTTP метод, обычно GET или PUT

.PARAMETER appliance
Адрес аплаинса, IP или FQDN

.PARAMETER url
URI для выполнения запроса

.PARAMETER value
Значение которое необходимо установить

.PARAMETER SetUserGroupIpPrecedence
Преднастроенный метод для установки значения параметра UserGroupIpPrecedence

.PARAMETER GetUserGroupIpPrecedence
Преднастроенный метод для получения значения параметра UserGroupIpPrecedence

.EXAMPLE
Invoke-WbsAPI-Request.ps1 -user admin -method get -url https://10.10.10.10/wse/filter/ini/FilteringManager/UserGroupIpPrecedence?value
Получение параметра UserGroupIpPrecedence модуля wse на аплаинсе 10.10.10.10, пароль будет запрошен скриптом отдельно

.EXAMPLE
Invoke-WbsAPI-Request.ps1 -user admin -pass p@ssw0rd -appliance 10.10.10.10 -GetUserGroupIpPrecedence
Получение параметра UserGroupIpPrecedence модуля wse на аплаинсе 10.10.10.10, с явным заданием пользователя и пароля

.EXAMPLE
Invoke-WbsAPI-Request.ps1 -user admin -appliance 10.10.10.10 -SetUserGroupIpPrecedence
Настройка для аплаинса 10.10.10.10 параметра UserGroupIpPrecedence

.EXAMPLE
Invoke-WbsAPI-Request.ps1 -user admin -pass p@ssw0rd -appliance 10.10.10.10 -SetUserGroupIpPrecedence -value true
Установка для аплаинса 10.10.10.10 параметра UserGroupIpPrecedence в true, с явным заданием пользователя и пароля

.NOTES
Alexander V Borisov
B&N Bank 2017

.LINK
http://www.binbank.ru
#>

Param
(
    [Parameter(Mandatory = $false, HelpMessage = "Username with admin rights")][string]$user,
    [Parameter(Mandatory = $false, HelpMessage = "Password")][string]$pass,
    [Parameter(Mandatory = $false, HelpMessage = "HTTP method, usaly GET or PUT")][string]$method,
    [Parameter(Mandatory = $false, HelpMessage = "Appliance address (ip or fqdn)")][string]$appliance,
    [Parameter(Mandatory = $false, HelpMessage = "URI to request")][string]$url,
    [Parameter(Mandatory = $false, HelpMessage = "Value to set")][string]$value,
    [Parameter(Mandatory = $false, HelpMessage = "SET parameter UserGroupIpPrecedence")][switch]$SetUserGroupIpPrecedence,
    [Parameter(Mandatory = $false, HelpMessage = "GET parameter UserGroupIpPrecedence")][switch]$GetUserGroupIpPrecedence
)

if (!$user) {$user = Read-Host "Username"}
if (!$pass) {
    $secpass = Read-Host "Password" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secpass)
    $pass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

# Workaround for allow SelfSigned Cert
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
                return true;
            }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
# and force TLS 1.2 (possible values: SystemDefault, Ssl3, Tls, Tls11, Tls12)
[System.Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function makeRequest ($fUser, $fPass, $fMethod, $fUrl) {
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($fUser + ":" + $fPass)))
    Write-Output (Invoke-RestMethod -UseBasicParsing -Method $fMethod -Headers @{Authorization = "Basic $base64AuthInfo"} -Uri $fUrl)
}

if ($SetUserGroupIpPrecedence) {
    $method = "PUT"
    if (!$appliance) {$appliance = Read-Host "Appliance address"}
    if (!$value) {$value = Read-Host "Value (true or false) [true]"}
    if (!$value) {$value = "true"}
    $url = ("https://" + $appliance + "/wse/filter/ini/FilteringManager/UserGroupIpPrecedence?value=" + $value)
    Write-Output (makeRequest -fUser $user -fPass $pass -fMethod $method -fUrl $url) | Format-List
}
elseif ($GetUserGroupIpPrecedence) {
    $method = "GET"
    if (!$appliance) {$appliance = Read-Host "Appliance address"}
    $url = ("https://" + $appliance + "/wse/filter/ini/FilteringManager/UserGroupIpPrecedence?value")
    Write-Output (makeRequest -fUser $user -fPass $pass -fMethod $method -fUrl $url) | Format-List
}
else {
    if (!$method) {$method = Read-Host "Method"}
    if (!$url) {$url = Read-Host "URL"}
    Write-Output (makeRequest -fUser $user -fPass $pass -fMethod $method -fUrl $url) | Format-List
}