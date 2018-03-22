# Short description
* **Invoke-WbsAPI-Request.ps1**  
A script that helps you perform queries to the appliance API with standard PowerShell tools.  
i.e. https://support.forcepoint.com/KBArticle?id=configure-filtering-service-via-api  
Use it if you can't use curl in Windows.  
Help on Russian only.

* **Scan-WbsApl-for-AvailHotfix.ps1**  
Scanning appliences for available hotfixes

* **Get-WbsURLCategory.ps1**  
Wrapper to WebsensePing.exe.  
With some cool features, also parse and reformat output.  
Can show you - AD groups of user (with custom filter), filtering policies and filtering result for request (user - user ip - url)  
Additionally, script can parse pac file and return proxy list for request (useful for big installations with many proxies).
Help and many message on Russian only.

* **Get-WebsensePing.ps1**  
Script for collect WebsensePing files from TRITON Web Security installation folder (default: "C:\Program Files\Websense\Web Security\bin").  
Use it for Get-WbsURLCategory.ps1.

* **Get-WbsApl-HotfixInfo.ps1**  
Parser for http://appliancehotfix.websense.com, fast way to get info about available hotfixes for forcepoint appliances.