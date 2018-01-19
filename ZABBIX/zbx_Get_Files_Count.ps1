#zbx_Get_Files_Count.ps1

Param
(
    [Parameter(Mandatory = $true, HelpMessage = "Path to folder")]$Path,
    [Parameter(Mandatory = $false, HelpMessage = "Timeout")]$Timeout
)
if ($Path -eq $null) {Exit}
if (!$Timeout) {$Timeout = -1}

function EnumFiles ($fld, $fTimeout=$Timeout) {
    $Job = Start-Job {

        $count = (Get-ChildItem -Path $args[0] -File -ErrorAction SilentlyContinue).Count
        if ($Error.Count -gt 0) {Write-Output -1}
        else {Write-Output $count}

    } -ArgumentList $fld
    $JobResult = Wait-Job $Job -Timeout $fTimeout
    if ($JobResult) {
        $result = Receive-Job $Job
        Stop-Job $Job
        Remove-Job $Job -Force
        Write-Output $result
    }
    else {
        Stop-Job $Job
        Remove-Job $Job -Force
        Write-Output -1
    }
}

Write-Output (EnumFiles($Path))