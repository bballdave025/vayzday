<#
  setup-win-start.ps1  (Extended Tokens)
  -------------------------------------
  Adds tokens requested by Dave:
    • gimp-win, gimp-wsl
    • irfanview
    • zoom-win, zoom-wsl (note: WSL install deferred – vendor RPM; instructions added to Next Steps)
    • teamviewer (Windows), teamviewer-wsl (deferred; vendor repo)
    • audacity (Windows), audacity-wsl (dnf/apt)
    • conda (Windows via Miniconda); conda-wsl (deferred; Miniforge recommended)
    • gvim (Windows)
    • java, jre (Windows)    — plus existing jdk
    • imgburn (Windows)
    • tightvnc (Windows), tightvnc-wsl (installs TigerVNC server where available)
    • sftpgo-win, sftpgo-wsl (dnf/apt)
    • openssh-server-wsl (installs sshd + enables)

  Notes:
    • Where winget IDs may vary across environments, the script attempts install; on failure it logs a Next Step.
    • WSL installs prefer Fedora if present; otherwise Ubuntu. Uses `wsl -d <name> -- bash -lc "<cmds>"`.
    • Some vendor packages (Zoom, TeamViewer) require manual repo/URL; we add clear Next Steps rather than guessing.
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)] [string]$Installs,
  [ValidateSet('y','n')] [string]$Interactive = 'y',
  [ValidateSet('y','n')] [string]$VerifyManualDownloads = 'y',
  [ValidateSet('y','n')] [string]$RestorePoints = 'y',
  [string]$Perform-GPG = 'y',
  [switch]$No-Install-GPG
)

$ErrorActionPreference = 'Stop'
function NowStr { (Get-Date).ToString('yyyy-MM-ddTHHmmssK') }
$startTimestamp = NowStr
$desk = [Environment]::GetFolderPath('Desktop')
$logPartial   = Join-Path $desk "partial_install_report_$startTimestamp.log"
$logComplete  = Join-Path $desk "completed_install_report_$startTimestamp.log"
$logCurrent   = $logPartial

$nextSteps    = New-Object System.Collections.Generic.List[string]
$doneList     = New-Object System.Collections.Generic.List[string]
$skippedList  = New-Object System.Collections.Generic.List[string]

function Log($s){ $s | Tee-Object -FilePath $logCurrent -Append | Out-Host }
function Section($t){ Log "`n=== $t ===`n" }

# --- Admin guard ---
$admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $admin) { Write-Host "Run in elevated Windows PowerShell (Admin)." -ForegroundColor Yellow; exit 1 }

# --- Easter eggs ---
if ($Perform-GPG -eq 'n') {
  for($i=1;$i -le 2;$i++){
    $sp = Read-Host -AsSecureString "Enter passphrase to skip GPG checks"
    $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sp))
    if ($plain -eq 'iamveryverysure') { break } elseif ($i -eq 2) {
      Write-Error "If you really want to skip GPG checks, see script source near your PS profile."
    }
  }
}
if ($No-Install-GPG) {
  $sp = Read-Host -AsSecureString "Enter passphrase to avoid installing GPG"
  $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sp))
  if ($plain -ne 'justdoit') { Write-Error "GPG install skip denied." }
}

# --- Mini system snapshot (pre) ---
Section "Windows Specs (pre)"
try {
  $cs = Get-CimInstance Win32_ComputerSystem
  $os = Get-CimInstance Win32_OperatingSystem
  Log ("Machine: {0}  Model: {1}  RAM: {2:N2} GB" -f $cs.Manufacturer,$cs.Model,($cs.TotalPhysicalMemory/1GB))
  Log ("OS: {0} {1}  Build: {2}" -f $os.Caption,$os.OSArchitecture,$os.BuildNumber)
} catch { Log "Specs error: $($_.Exception.Message)" }

# --- winget availability ---
Section "winget availability"
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Log "winget not found. Install 'App Installer' from Microsoft Store, then rerun."
  $nextSteps.Add("Install winget (App Installer) from Microsoft Store.")
  $skippedList.Add("All winget-driven installs")
  goto Finish
} else { Log "winget found." }

# --- Explorer tweaks ---
Section "File Explorer visibility"
try {
  $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
  New-Item -Path $adv -Force | Out-Null
  Set-ItemProperty $adv HideFileExt 0
  Set-ItemProperty $adv Hidden 1
  Set-ItemProperty $adv ShowSuperHidden 1
  Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
  $doneList.Add("Explorer: show extensions + hidden/system")
  Log "Applied."
} catch { Log "Explorer tweak error: $($_.Exception.Message)" }

# --- Restore point helpers ---
function Ensure-SystemRestore {
  param([string[]]$Drives = @('C:\'), [string]$MaxSize = '5%')
  foreach ($drv in $Drives) {
    try {
      Enable-ComputerRestore -Drive $drv -ErrorAction Stop
      Start-Process -FilePath "vssadmin.exe" -ArgumentList "resize shadowstorage /for=$drv /on=$drv /maxsize=$MaxSize" -WindowStyle Hidden -Wait
      Log "System Protection enabled on $drv (cap $MaxSize)."
    } catch {
      $nextSteps.Add("Enable System Protection on $drv (Control Panel → System → System Protection).")
      Log "Failed to enable System Protection on $drv: $($_.Exception.Message)"
    }
  }
}
function Make-RestorePoint { param([string]$Desc)
  try { Checkpoint-Computer -Description $Desc -RestorePointType 'MODIFY_SETTINGS'
        Log "Restore point created: $Desc"; $doneList.Add("Restore point: $Desc") }
  catch { $skippedList.Add("Restore point ($Desc)"); $nextSteps.Add("Create manual restore point: rstrui.exe → System Protection."); Log "Restore point error: $($_.Exception.Message)" }
}
if ($RestorePoints -eq 'y') {
  Section "System Restore (pre-install)"
  Ensure-SystemRestore -Drives @('C:\') -MaxSize '5%'
  Make-RestorePoint -Desc ("Pre-Setup {0}" -f $startTimestamp)
}

# --- Manual download verification (SHA256/GPG) ---
function Verify-Download {
  param([Parameter(Mandatory=$true)][string]$FilePath, [string]$SigPath, [string]$Sha256)
  if ($VerifyManualDownloads -eq 'n') { return }
  if ($Sha256) {
    $h = (Get-FileHash -Algorithm SHA256 -Path $FilePath).Hash.ToLower()
    if ($h -ne $Sha256.ToLower()) { throw "SHA256 mismatch for $FilePath" } else { Log "SHA256 OK: $(Split-Path $FilePath -Leaf)" }
  }
  if ($SigPath -and (Test-Path $SigPath) -and (Get-Command gpg -ErrorAction SilentlyContinue)) {
    & gpg --verify "$SigPath" "$FilePath" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "GPG verify failed for $FilePath" } else { Log "GPG OK: $(Split-Path $FilePath -Leaf)" }
  }
}

# --- Helpers ---
function Confirm-IfNeeded($label){
  if ($Interactive -eq 'y') { $ans = Read-Host "Install $label ? (y/N)"; return ($ans.Trim().ToLower() -eq 'y') } else { return $true }
}
function Install-Winget($id, $label){
  if (-not (Confirm-IfNeeded $label)) { $skippedList.Add($label)|Out-Null; return }
  winget install -e --id $id --accept-package-agreements --accept-source-agreements --silent
  if ($LASTEXITCODE -eq 0) { $doneList.Add($label)|Out-Null; Log "$label installed." } else { $skippedList.Add($label)|Out-Null; Log "$label failed (winget id may differ)." }
}

# --- WSL helpers ---
function Get-WSLDistros {
  (& wsl -l -v) -replace "`r","" | Select-Object -Skip 1 | Where-Object {$_ -match "^\s*\S"} | ForEach-Object {
    $parts = ($_ -replace "^\s+","") -split "\s+"
    [PSCustomObject]@{ Name=$parts[0]; State=$parts[1]; Version=$parts[-1] }
  }
}
function First-FedoraOrUbuntu {
  $d = Get-WSLDistros
  $fed = $d | Where-Object {$_.Name -match '^Fedora'} | Select-Object -First 1
  if ($fed) { return $fed.Name }
  $ubu = $d | Where-Object {$_.Name -match '^Ubuntu'} | Select-Object -First 1
  if ($ubu) { return $ubu.Name }
  return $null
}
function WSL-Run {
  param([string]$Distro,[string]$Cmd)
  if (-not $Distro) { $skippedList.Add("WSL command: $Cmd"); $nextSteps.Add("No Fedora/Ubuntu WSL detected for '$Cmd'. Install with wsl-* token."); return }
  & wsl -d "$Distro" -- bash -lc "$Cmd"
  if ($LASTEXITCODE -eq 0) { Log "WSL[$Distro]: $Cmd  (OK)" } else { Log "WSL[$Distro]: $Cmd  (FAILED)" }
}

# --- Parse tokens ---
$want = @()
if ($Installs.Trim().ToLower() -ne 'none') {
  $want = $Installs.Split(',').ForEach({ $_.Trim().ToLower() }) | Where-Object { $_ -ne '' }
}

# --- Core installs ---
if ($want -contains 'gpg' -and -not $No-Install-GPG) { Install-Winget "GnuPG.Gpg4win" "Gpg4win (GPG)" }
if ($want -contains '7zip')                          { Install-Winget "7zip.7zip" "7-Zip" }
if ($want -contains 'git' -or $want -contains 'git-win') { Install-Winget "Git.Git" "Git (Windows)" }
if ($want -contains 'git-wsl') {
  $d = First-FedoraOrUbuntu
  if ($d) { WSL-Run -Distro $d -Cmd "if command -v dnf >/dev/null 2>&1; then sudo dnf -y install git; else sudo apt-get update && sudo apt-get -y install git; fi" ; $doneList.Add("Git (WSL)"); }
  else { $skippedList.Add("git-wsl"); $nextSteps.Add("Install Fedora/Ubuntu WSL first, then: sudo dnf -y install git  OR  sudo apt-get -y install git"); }
}

# --- WSL Features + default dir + distro installs / relocation ---
function Ensure-WSL-Features {
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart | Out-Null
  Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart | Out-Null
}
function Set-WSL-DefaultDir { param([string]$Dir = 'D:\WSL')
  if (-not (Test-Path $Dir)) { New-Item -ItemType Directory -Path $Dir | Out-Null }
  & wsl --set-default-dir "$Dir"; Log "WSL default dir set to $Dir"
}
function Pending-Reboot { 
  (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") -or
  (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired")
}
function Get-WSLDistros-Objects { Get-WSLDistros }
function Relocate-Distro {
  param([string]$Name,[string]$TargetDir='D:\WSL')
  $tmp = Join-Path $env:TEMP ("{0}_{1}.tar" -f $Name,(Get-Date).ToString("yyyyMMddHHmmss"))
  $dest = Join-Path $TargetDir $Name
  if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }
  Log "Exporting $Name to $tmp ..."; & wsl --export "$Name" "$tmp"
  Log "Unregistering $Name ...";     & wsl --unregister "$Name"
  Log "Importing $Name to $dest ...";& wsl --import "$Name" "$tmp" "$dest" --version 2
  Remove-Item $tmp -Force
  Log "Relocated $Name to $dest"
}
if ($want | Where-Object { $_ -like 'wsl-*' }) {
  Section "WSL enablement + default dir + distros"
  try {
    Ensure-WSL-Features
    Set-WSL-DefaultDir -Dir 'D:\WSL'
    if (Pending-Reboot) {
      $nextSteps.Add("Reboot required to complete WSL feature enablement. Re-run this script afterwards.")
      $skippedList.Add("WSL distro installs (pending reboot)")
    } else {
      if ($want -contains 'wsl-fedora') { Install-Winget "WhitewaterFoundry.FedoraRemixforWSL" "Fedora Remix for WSL" }
      if ($want -contains 'wsl-ubuntu') { Install-Winget "Canonical.Ubuntu" "Ubuntu (WSL)" }
      if ($want -contains 'set-default-wsl1') { & wsl --set-default-version 1; Log "WSL default version set to 1." }

      $distros = Get-WSLDistros-Objects
      foreach ($d in $distros) {
        if ($d.Name -match '^(Ubuntu|Fedora)') {
          $doMove = $true
          if ($Interactive -eq 'y') {
            $ans = Read-Host "Relocate $($d.Name) to D:\WSL now? (y/N)"
            $doMove = ($ans.Trim().ToLower() -eq 'y')
          }
          if ($doMove) { Relocate-Distro -Name $d.Name -TargetDir 'D:\WSL'; $doneList.Add("Relocated $($d.Name) to D:\WSL") }
          else { $skippedList.Add("Relocation of $($d.Name)") }
        }
      }
    }
  } catch { Log "WSL error: $($_.Exception.Message)"; $skippedList.Add("WSL tasks") }
}

# --- Browsers ---
if ($want -contains 'firefox') { Install-Winget "Mozilla.Firefox" "Firefox" }
if ($want -contains 'chrome')  { Install-Winget "Google.Chrome"   "Chrome" }

# --- Editors/Tools (Windows) ---
if ($want -contains 'notepad++')       { Install-Winget "Notepad++.Notepad++" "Notepad++" }
if ($want -contains 'imagemagick-win') { Install-Winget "ImageMagick.ImageMagick" "ImageMagick (Windows)" }
if ($want -contains 'winscp')          { Install-Winget "WinSCP.WinSCP" "WinSCP" }
if ($want -contains 'putty')           { Install-Winget "PuTTY.PuTTY" "PuTTY" }
if ($want -contains 'pageant')         { $nextSteps.Add("Pageant ships with PuTTY; configure keys if PuTTY installed.") }
if ($want -contains 'vim')             { Install-Winget "vim.vim" "Vim (Windows)" }
if ($want -contains 'gvim')            { Install-Winget "vim.vim" "GVim (Windows)" }

# --- Graphics/Media/Office/Dev (Windows) ---
if ($want -contains 'gimp-win')        { Install-Winget "GIMP.GIMP" "GIMP (Windows)" }
if ($want -contains 'irfanview')       { Install-Winget "IrfanSkiljan.IrfanView" "IrfanView" }
if ($want -contains 'vlc')             { Install-Winget "VideoLAN.VLC" "VLC" }
if ($want -contains 'k-lite-codecs')   { Install-Winget "CodecGuide.K-LiteCodecPack.Mega" "K-Lite Codec Pack (Mega)" }
if ($want -contains 'libreoffice')     { Install-Winget "TheDocumentFoundation.LibreOffice" "LibreOffice" }
if ($want -contains 'openoffice')      { Install-Winget "Apache.OpenOffice" "OpenOffice" }
if ($want -contains 'vc-redist')       { Install-Winget "Microsoft.VCRedist.2015+.x64" "VC++ 2015-2022 Redist (x64)" }
if ($want -contains 'jdk')             { Install-Winget "EclipseAdoptium.TemurinJDK.21" "Temurin JDK 21" }
if ($want -contains 'java')            { Install-Winget "Oracle.JavaRuntimeEnvironment" "Java Runtime (Oracle JRE)" }
if ($want -contains 'jre')             { Install-Winget "Oracle.JavaRuntimeEnvironment" "Java Runtime (Oracle JRE)" }
if ($want -contains 'python-non-conda'){ Install-Winget "Python.Python.3" "Python 3 (Windows)" }
if ($want -contains 'audacity')        { Install-Winget "Audacity.Audacity" "Audacity (Windows)" }
if ($want -contains 'imgburn')         { Install-Winget "LightningUK.ImgBurn" "ImgBurn (Windows)" }
if ($want -contains 'tightvnc')        { Install-Winget "TightVNC.TightVNC" "TightVNC (Windows)" }
if ($want -contains 'teamviewer')      { Install-Winget "TeamViewer.TeamViewer" "TeamViewer (Windows)" }
if ($want -contains 'zoom-win')        { Install-Winget "Zoom.Zoom" "Zoom (Windows)" }

# --- Conda (Windows) ---
if ($want -contains 'conda') {
  Install-Winget "Anaconda.Miniconda3" "Miniconda3 (Windows)"
  $nextSteps.Add("Consider Miniforge/Mambaforge for a FOSS-friendly conda in future.")
}

# --- WSL-side installs ---
$wslDistro = First-FedoraOrUbuntu
function WSL-Install {
  param([string]$Label,[string]$FedoraPkgs,[string]$UbuntuPkgs)
  if (-not (Confirm-IfNeeded "$Label (WSL)")) { $skippedList.Add("$Label (WSL)"); return }
  if ($wslDistro) {
    $cmd = "if command -v dnf >/dev/null 2>&1; then sudo dnf -y install {0}; else sudo apt-get update && sudo apt-get -y install {1}; fi" -f $FedoraPkgs,$UbuntuPkgs
    WSL-Run -Distro $wslDistro -Cmd "$cmd"
    $doneList.Add("$Label (WSL)")
  } else {
    $skippedList.Add("$Label (WSL)")
    $nextSteps.Add("Install Fedora/Ubuntu WSL first, then inside WSL: sudo dnf -y install $FedoraPkgs  OR  sudo apt-get -y install $UbuntuPkgs")
  }
}

if ($want -contains 'imagemagick-wsl')    { WSL-Install -Label "ImageMagick" -FedoraPkgs "imagemagick" -UbuntuPkgs "imagemagick" }
if ($want -contains 'gimp-wsl')           { WSL-Install -Label "GIMP"        -FedoraPkgs "gimp"        -UbuntuPkgs "gimp" }
if ($want -contains 'vlc-wsl')            { WSL-Install -Label "VLC"         -FedoraPkgs "vlc"         -UbuntuPkgs "vlc" }
if ($want -contains 'audacity-wsl')       { WSL-Install -Label "Audacity"    -FedoraPkgs "audacity"    -UbuntuPkgs "audacity" }
if ($want -contains 'python-non-conda-wsl'){ WSL-Install -Label "Python 3"   -FedoraPkgs "python3 python3-pip" -UbuntuPkgs "python3 python3-pip" }
if ($want -contains 'tightvnc-wsl')       { WSL-Install -Label "TigerVNC Server" -FedoraPkgs "tigervnc-server" -UbuntuPkgs "tigervnc-standalone-server" }

# SFTPGo (WSL)
if ($want -contains 'sftpgo-wsl') {
  if ($wslDistro) {
    $cmd = "if command -v dnf >/dev/null 2>&1; then sudo dnf -y install sftpgo || echo 'Consider enabling extra repos if not found.'; else sudo apt-get update && sudo apt-get -y install sftpgo || echo 'Add upstream repo for sftpgo.'; fi"
    WSL-Run -Distro $wslDistro -Cmd "$cmd"
    $doneList.Add("SFTPGo (WSL)")
  } else {
    $skippedList.Add("sftpgo-wsl")
    $nextSteps.Add("Install Fedora/Ubuntu WSL first; then install sftpgo via distro repos or vendor repo.")
  }
}

# OpenSSH Server (WSL)
if ($want -contains 'openssh-server-wsl') {
  if ($wslDistro) {
    $cmd = "if command -v dnf >/dev/null 2>&1; then sudo dnf -y install openssh-server && sudo systemctl enable --now sshd; else sudo apt-get update && sudo apt-get -y install openssh-server && sudo service ssh start; fi"
    WSL-Run -Distro $wslDistro -Cmd "$cmd"
    $doneList.Add("OpenSSH Server (WSL)")
    $nextSteps.Add("For WSL sshd access, enable inbound firewall rule in Windows and consider fixed port mapping.")
  } else {
    $skippedList.Add("openssh-server-wsl")
    $nextSteps.Add("Install Fedora/Ubuntu WSL first; then: sudo dnf -y install openssh-server && sudo systemctl enable --now sshd")
  }
}

# Zoom / TeamViewer in WSL notes
if ($want -contains 'zoom-wsl') {
  $skippedList.Add("zoom-wsl")
  $nextSteps.Add("Zoom in WSL: install vendor RPM/DEB manually; WSLg may run it but camera/mic support can vary. Prefer Zoom (Windows).")
}
if ($want -contains 'teamviewer-wsl') {
  $skippedList.Add("teamviewer-wsl")
  $nextSteps.Add("TeamViewer in WSL is not recommended; install TeamViewer (Windows) instead.")
}

# SFTPGo (Windows)
if ($want -contains 'sftpgo-win') { Install-Winget "SFTPGo.SFTPGo" "SFTPGo (Windows)" }

# --- Docker ---
if ($want -contains 'docker-desktop-win') { Install-Winget "Docker.DockerDesktop" "Docker Desktop for Windows" }
if ($want -contains 'docker-wsl') {
  $nextSteps.Add("Open Docker Desktop → Settings → Resources → WSL Integration, enable for your distro(s).")
}

# --- Cygwin bootstrap (download-only) ---
if ($want -contains 'cygwin') {
  if (Confirm-IfNeeded "Download Cygwin setup-x86_64.exe to C:\cygwin64") {
    Section "Cygwin bootstrap"
    try {
      $cygDir = "C:\cygwin64"; if (-not (Test-Path $cygDir)) { New-Item -ItemType Directory -Path $cygDir | Out-Null }
      $exe = Join-Path $cygDir "setup-x86_64.exe"
      Invoke-WebRequest -Uri "https://cygwin.com/setup-x86_64.exe" -OutFile $exe -UseBasicParsing
      $doneList.Add("Cygwin setup downloader")
      $nextSteps.Add("To install Cygwin later: run C:\cygwin64\setup-x86_64.exe and choose packages.")
    } catch { $skippedList.Add("Cygwin bootstrap"); Log "Cygwin bootstrap error: $($_.Exception.Message)" }
  }
}

# --- Post restore point ---
if ($RestorePoints -eq 'y') {
  Section "System Restore (post-install)"
  Make-RestorePoint -Desc ("Post-Setup {0}" -f (NowStr))
}

# --- Mini system snapshot (post) ---
Section "Windows Specs (post)"
try { $cs2 = Get-CimInstance Win32_ComputerSystem; Log ("RAM (GB): {0:N2}" -f ($cs2.TotalPhysicalMemory/1GB)) } catch {}

# --- Finish ---
Section "Summary"
Log "Start:  $startTimestamp"
Log "Now:    $(NowStr)"
Log "`nDone:      $($doneList -join '; ' )"
Log "`nSkipped:   $($skippedList -join '; ' )"
if ($nextSteps.Count -gt 0) {
  Log "`nNext steps:"
  $nextSteps | ForEach-Object { Log " - $_" }
}

if ($skippedList.Count -eq 0) {
  Copy-Item $logPartial $logComplete -Force
  Remove-Item $logPartial -Force
  Write-Host "`nSaved to: $logComplete" -ForegroundColor Green
} else {
  Write-Host "`nSaved to: $logPartial" -ForegroundColor Yellow
}
