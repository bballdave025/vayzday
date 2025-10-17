# portable_profile.ps1
# A portable PowerShell profile you can dot-source from any host profile.
# Provides timestamp helpers, execution policy helpers, sudo, and screen-brightness utilities.

function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p  = New-Object Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    } catch { return $false }
}

function Get-Timestamp {
    $epoch = [int64]([DateTimeOffset]::Now.ToUnixTimeSeconds())
    $iso   = (Get-Date).ToString("yyyy-MM-dd'T'HHmmsszzz") -replace ":", ""
    return "${epoch}_${iso}"
}
Set-Alias timestamp Get-Timestamp
Set-Alias ttdate    Get-Timestamp

function Get-IsoTimestampCompact {
    $epoch = [int64]([DateTimeOffset]::Now.ToUnixTimeSeconds())
    $iso   = (Get-Date).ToString("yyyyMMdd'T'HHmmsszzz") -replace ":", ""
    return "${epoch}_${iso}"
}
Set-Alias iso-timestamp  Get-IsoTimestampCompact
Set-Alias ts_iso_compact Get-IsoTimestampCompact
Set-Alias ts_iso_short   Get-IsoTimestampCompact

function Get-IsoTimestampWeb {
    $epoch = [int64]([DateTimeOffset]::Now.ToUnixTimeSeconds())
    $iso   = (Get-Date).ToString("yyyy-MM-dd'T'HH:mm:sszzz")
    return "${epoch}_${iso}"
}
Set-Alias ts_iso_webby Get-IsoTimestampWeb
Set-Alias ts_iso_long  Get-IsoTimestampWeb

function Get-IsoOnlyShort { (Get-Date).ToString("yyyyMMdd'T'HHmmsszzz") -replace ":", "" }
Set-Alias iso-only-timestamp-short Get-IsoOnlyShort

function Get-IsoOnlyLong  { (Get-Date).ToString("yyyy-MM-dd'T'HH:mm:sszzz") }
Set-Alias iso-only-timestamp-long  Get-IsoOnlyLong

function Use-SessionPolicy {
    Write-Host "Setting execution policy for THIS PowerShell process only: Bypass" -ForegroundColor Cyan
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
}

function Use-StrictPolicy {
    if (-not (Test-IsAdmin)) {
        Write-Warning "Use-StrictPolicy changes system/user policy; re-run PowerShell as Administrator."
        return
    }
    Write-Host "Setting LocalMachine policy to AllSigned (requires Administrator)..." -ForegroundColor Yellow
    Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy AllSigned -Force
}

function Use-UserRemoteSigned {
    if (-not (Test-IsAdmin)) {
        Write-Host "CurrentUser scope does not require Admin; proceeding..." -ForegroundColor Cyan
    }
    Write-Host "Setting CurrentUser policy to RemoteSigned..." -ForegroundColor Yellow
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
}

function sudo {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $FilePath,
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]] $Arguments
    )
    $argLine = if ($Arguments) { $Arguments -join ' ' } else { "" }
    Write-Host "Elevating: $FilePath $argLine" -ForegroundColor Cyan
    Start-Process -FilePath $FilePath -ArgumentList $argLine -Verb RunAs
}

function sudo-pwsh {
    $here = (Get-Location).Path
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit","-Command","Set-Location -LiteralPath '$here'" -Verb RunAs
}

function Set-Brightness {
    param([Parameter(Mandatory=$true)][ValidateRange(0,100)][int]$Percent)
    try {
        $methods = Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods -ErrorAction Stop
        foreach ($m in $methods) {
            $m.WmiSetBrightness(1, [byte]$Percent) | Out-Null
        }
        Write-Host "Brightness set to $Percent%." -ForegroundColor Green
    } catch {
        Write-Warning "Could not set brightness via WMI (external monitor? vendor driver?). Try Windows Mobility Center or OEM utility."
    }
}

function Dim-ForReading { Set-Brightness -Percent 30 }
function Max-Brightness { Set-Brightness -Percent 100 }

Set-Alias ll Get-ChildItem
Set-Alias grep Select-String
Set-Alias which Get-Command

Write-Host ("Loaded portable_profile.ps1  —  " + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor Gray
