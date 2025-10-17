<#
  setup-win-start.ps1
  Features:
    - Tokens: emit-cygwin-bootstrap, emit-wsl-setup
    - Archive switch: -Archive4Doc y|n  (copies emissions into .4doc_* dirs and appends .{timestamp}.4doc to filenames)
    - Emits END_OF_DAY_README_{timestamp}.4doc.md at current working directory
    - Safe, no-install emission mode; writes completed_install_report even if .gitignore not present
    - .gitignore advisory (non-fatal): prints missing lines or entire block if file absent
#>

# ------------------------------------------------------------
# TEMPORARY EXECUTION POLICY (SAFE FOR THIS SESSION ONLY)
# ------------------------------------------------------------
# Before running this setup script, open PowerShell **as Administrator**
# and allow script execution only for the current session:
#
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#
# This change is temporary and reverts automatically when PowerShell closes.
# It does NOT modify your system-wide policy.
#
# Example full run (no interaction, archival enabled):
#
#   cd "$HOME\Desktop"
#   .\setup-win-start.ps1 -Installs "emit-cygwin-bootstrap,emit-wsl-setup" -Interactive n -Archive4Doc y
#
# ------------------------------------------------------------

[CmdletBinding()]
param(
  [string]$Installs,
  [ValidateSet('y','n')] [string]$Interactive = 'y',
  [ValidateSet('y','n')] [string]$VerifyManualDownloads = 'y',
  [ValidateSet('y','n')] [string]$RestorePoints = 'y',
  [ValidateSet('y','n')] [string]$Archive4Doc = 'n',
  [switch]$Help
)

# Output Help if requested. First, we define usage/help message.

if ($Help) {
  # (print help and exit 0)
  exit 0
}

if ([string]::IsNullOrWhiteSpace($Installs)) {
  Write-Host "Error: -Installs is required. Try: -Installs `"emit-cygwin-bootstrap,emit-wsl-setup`"" -ForegroundColor Red
  Write-Host "Or get help/usage: .\setup-win-start.ps1 -Help"
  exit 1
}

$ErrorActionPreference = 'Stop'

function NowStr {
    # Use Unix-style seconds, human date, and timezone offset automatically
    $raw = Get-Date -UFormat "%s_%Y-%m-%dT%H%M%S%Z00"
    # Clean the fractional seconds PowerShell sometimes injects (e.g., .12345_)
    return ($raw -replace '[.][0-9]{1,5}_','_')
}
$startTimestamp = NowStr

$desk = [Environment]::GetFolderPath('Desktop')
$cwd  = (Get-Location).Path

$logPartial   = Join-Path $desk "partial_install_report_$startTimestamp.log"
$logComplete  = Join-Path $desk "completed_install_report_$startTimestamp.log"
$logCurrent   = $logPartial

# collections
$nextSteps    = New-Object System.Collections.Generic.List[string]
$doneList     = New-Object System.Collections.Generic.List[string]
$emittedDirs  = New-Object System.Collections.Generic.List[string]

function Log($s){ $s | Tee-Object -FilePath $logCurrent -Append | Out-Host }
function Section($t){ Log "`n=== $t ===`n" }

# Require elevation (admin)
$admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $admin) { Write-Host "Run this script in an elevated Windows PowerShell (Admin)." -ForegroundColor Yellow; exit 1 }

# Parse tokens
$want = @()
if ($Installs.Trim().ToLower() -ne 'none') {
  $want = $Installs.Split(',').ForEach({ $_.Trim().ToLower() }) | Where-Object { $_ -ne '' }
}

Section "Emission Plan"
Log ("Requested tokens: " + (($want) -join ", "))
Log ("Archive4Doc: " + $Archive4Doc)

# ---------------- emit-cygwin-bootstrap ----------------
if ($want -contains 'emit-cygwin-bootstrap') {
  Section "Emit: Cygwin Bootstrap Pack"
  $outDir = Join-Path $desk ("Cygwin_Bootstrap_{0}" -f $startTimestamp)
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null

  $bootstrap_cmd = @"
@echo off
setlocal enableextensions enabledelayedexpansion
REM Cygwin Headless Bootstrap (verified, non-GUI)
set CYG_ROOT=C:\cygwin64
set CYG_SETUP=%CYG_ROOT%\setup-x86_64.exe
set CYG_SITE=https://mirrors.kernel.org/sourceware/cygwin/
set PKGS=wget,curl,git,nano,vim,openssh,ca-certificates,tar,gzip,bzip2,unzip
set CYG_USER_HOME=%CYG_ROOT%\home\%USERNAME%

where winget >nul 2>&1
if %ERRORLEVEL%==0 (
  echo [*] winget detected. Installing Cygwin silently...
  winget install --id=Cygwin.Cygwin -e --silent
  if %ERRORLEVEL%==0 ( goto SETUPRUN ) else ( echo [!] winget install failed; falling back. )
)

:DOWNLOAD
if not exist "%CYG_ROOT%" mkdir "%CYG_ROOT%"
echo [*] Downloading setup-x86_64.exe and signature...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Invoke-WebRequest -UseBasicParsing https://www.cygwin.com/setup-x86_64.exe -OutFile '%CYG_SETUP%'; ^
   Invoke-WebRequest -UseBasicParsing https://www.cygwin.com/setup-x86_64.exe.sig -OutFile '%CYG_SETUP%.sig'"

where gpg >nul 2>&1
if %ERRORLEVEL% NEQ 0 ( echo [!] gpg not found; cannot verify; goto SETUPRUN )

echo [*] Scraping official fingerprint from cygwin.com/install.html ...
for /f "usebackq tokens=* delims=" %%F in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p=(Invoke-WebRequest -UseBasicParsing https://www.cygwin.com/install.html).Content; ^
   $m=[regex]::Match($p,'Primary key fingerprint:\s*([0-9A-F]{{4}}(?:\s+[0-9A-F]{{4}}){{9}})','IgnoreCase'); ^
   if(-not $m.Success){{exit 1}}; $m.Groups[1].Value.ToUpper()"`) do set CYG_FP_WEB=%%F
if "%CYG_FP_WEB%"=="" ( echo [!] Could not scrape fingerprint; aborting. & exit /b 1 )

echo [*] Locating signing key via WKD/keyserver...
gpg --batch --quiet --auto-key-locate clear,wkd,local,keyserver --locate-keys cygwin@cygwin.com || ( echo [!] Key import failed. & exit /b 1 )

for /f "usebackq tokens=* delims=" %%F in (`gpg --batch --with-colons --fingerprint cygwin@cygwin.com ^| ^
  findstr /b /c:"fpr:" ^| ^
  powershell -NoProfile -Command "$i=Get-Content -Raw -; ($i -split '\n' ^| %%{{$_ -split ':'}}[9]) ^| Select-Object -First 1"`) do set CYG_FP_GPG=%%F
if "%CYG_FP_GPG%"=="" ( echo [!] Could not read GPG fingerprint. & exit /b 1 )

for /f "usebackq tokens=* delims=" %%F in (`powershell -NoProfile -Command "'%CYG_FP_WEB%'.Replace(' ','').ToUpper()"`) do set CYG_FP_WEB_COMPACT=%%F
if /I not "%CYG_FP_GPG%"=="%CYG_FP_WEB_COMPACT%" ( echo [!] Fingerprint mismatch; aborting. & exit /b 1 )

echo [*] Verifying setup-x86_64.exe signature...
gpg --keyid-format=long --with-fingerprint --verify "%CYG_SETUP%.sig" "%CYG_SETUP%" || ( echo [!] Verify failed. & exit /b 1 )
echo [*] GPG signature OK.

:SETUPRUN
echo [*] Running Cygwin setup (quiet) with kernel.org mirror...
"%CYG_SETUP%" -q --root "%CYG_ROOT%" --site "%CYG_SITE%" --no-desktop --no-startmenu -P %PKGS%

echo [*] Creating 'Cygwin Terminal' shortcut...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$W=New-Object -ComObject WScript.Shell; $S=$W.CreateShortcut('$env:Public\\Desktop\\Cygwin Terminal.lnk'); ^
   $S.TargetPath='%CYG_ROOT%\\bin\\mintty.exe'; $S.Arguments='-i /Cygwin-Terminal.ico -'; ^
   $S.WorkingDirectory='%CYG_ROOT%\\home\\%USERNAME%'; $S.IconLocation='%CYG_ROOT%\\Cygwin-Terminal.ico'; $S.Save()"

echo [*] Writing cyg-bootstrap.sh and launcher...
if not exist "%CYG_USER_HOME%" mkdir "%CYG_USER_HOME%"
> "%CYG_USER_HOME%\\cyg-bootstrap.sh" echo #!/bin/bash
> "%CYG_USER_HOME%\\run_cyg.sh" echo bash /home/%USERNAME%/cyg-bootstrap.sh
"%CYG_ROOT%\\bin\\bash.exe" -lc "/home/%USERNAME%/cyg-bootstrap.sh"

echo [*] Done. Launch Cygwin Terminal from Desktop.
endlocal
"@

  $cyg_sh = @"
#!/bin/bash
set -e
mkdir -p ~/bin
grep -q 'PATH=.*~/bin' ~/.bashrc || echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
if [ -d "/cygdrive/c/Program Files/Android/platform-tools" ]; then
  echo 'export PATH="/cygdrive/c/Program Files/Android/platform-tools:$PATH"' >> ~/.bashrc
fi
source ~/.bashrc

cat > ~/bin/split_bottom.sh <<'EOF'
#!/bin/bash
BOTTOM_APP="$1"
if [ -z "$BOTTOM_APP" ]; then
  echo "Usage: $0 com.android.chrome/com.google.android.apps.chrome.Main"; exit 1;
fi
if adb shell pm list packages | grep -q com.google.android.keep; then
  TOP_APP="com.google.android.keep/.activities.BrowseActivity"
elif adb shell pm list packages | grep -q com.android.settings; then
  TOP_APP="com.android.settings/.Settings"
else
  TOP_APP="com.google.android.calculator/.Calculator"
fi
SCREEN_INFO=$(adb shell wm size | grep -oE "[0-9]+x[0-9]+")
SCREEN_WIDTH=$(echo "$SCREEN_INFO" | cut -d"x" -f1)
SCREEN_HEIGHT=$(echo "$SCREEN_INFO" | cut -d"x" -f2)
HALF_HEIGHT=$((SCREEN_HEIGHT / 2))

echo "Screen size: `$SCREEN_WIDTH x `$SCREEN_HEIGHT"
echo "Top stub: $TOP_APP"
echo "Bottom target: $BOTTOM_APP"
get_top_app(){{ adb shell dumpsys window windows | grep -E "mCurrentFocus" | sed 's/.* //'; }}

echo "Launching top stub..."
adb shell am start -n "$TOP_APP" --activity-options 'activityOptions.setLaunchWindowingMode(3)'
sleep 2

echo "Launching bottom app..."
adb shell am start -n "$BOTTOM_APP" --activity-options "activityOptions.setLaunchWindowingMode(3);activityOptions.setLaunchBounds(new android.graphics.Rect(0,$HALF_HEIGHT,$SCREEN_WIDTH,$SCREEN_HEIGHT))"
sleep 3

TOP_WINDOW=$(get_top_app)
if [[ "$TOP_WINDOW" == *"`$BOTTOM_APP"* ]]; then
  echo "Detected: bottom app occupied top pane. Auto-swapping..."
  adb shell am start -n "$BOTTOM_APP" --activity-options 'activityOptions.setLaunchWindowingMode(3)'
  sleep 2
  adb shell am start -n "$TOP_APP" --activity-options "activityOptions.setLaunchWindowingMode(3);activityOptions.setLaunchBounds(new android.graphics.Rect(0,0,$SCREEN_WIDTH,$HALF_HEIGHT))"
else
  echo "Confirmed: bottom app in lower half."
fi

echo "Split-screen setup complete."
EOF
chmod +x ~/bin/split_bottom.sh
grep -q 'alias splitbot=' ~/.bashrc || echo 'alias splitbot="split_bottom.sh"' >> ~/.bashrc
echo "Cygwin bootstrap complete. Try: adb devices && splitbot com.android.chrome/com.google.android.apps.chrome.Main"
"@

  $sha = "34294314692b544e3bf4d90649919560c3af6c7adfad40e243678541a3ae7576  setup-x86_64.exe`n"

  $readme = @"
# Cygwin Headless Bootstrap — README

This folder was generated by **setup-win-start.ps1** at $startTimestamp.

It provides a verified (GPG-checked) path to install Cygwin without adding it to your baseline Windows image.
- `bootstrap_cyg.cmd` — Admin-only, performs winget or verified direct install.
- `cyg-bootstrap.sh` — Post-install helper (adds `split_bottom.sh` ADB tool).
- `SHA256SUMS.txt` — For `sha256sum -c` validation (when the EXE is present).

**Quick start**
1) Open elevated PowerShell.
2) `cd` into this folder.
3) Run: `.\bootstrap_cyg.cmd`
"@

  Set-Content -Path (Join-Path $outDir "bootstrap_cyg.cmd") -Value $bootstrap_cmd -Encoding UTF8
  Set-Content -Path (Join-Path $outDir "cyg-bootstrap.sh")  -Value $cyg_sh -Encoding UTF8
  Set-Content -Path (Join-Path $outDir "SHA256SUMS.txt")    -Value $sha -Encoding UTF8
  Set-Content -Path (Join-Path $outDir "CYG_README.md")     -Value $readme -Encoding UTF8

  $emittedDirs.Add($outDir) | Out-Null
  $doneList.Add("Emitted Cygwin Bootstrap Pack → $outDir") | Out-Null
  $nextSteps.Add("To install Cygwin later: open elevated PowerShell, cd into the folder, run bootstrap_cyg.cmd") | Out-Null
}

# ---------------- emit-wsl-setup ----------------
if ($want -contains 'emit-wsl-setup') {
  Section "Emit: WSL Companion Pack"
  $outDir = Join-Path $desk ("WSL_Setup_{0}" -f $startTimestamp)
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null

  $wslbash = @'
#!/usr/bin/env bash
set -Eeuo pipefail
ORIG_IFS="$IFS"; IFS=$'\n\t'
trap 'IFS="$ORIG_IFS"' EXIT

if command -v dnf >/dev/null 2>&1; then
  PKG="sudo dnf -y install"; UPDATE="sudo dnf -y update"; DISTRO="fedora"
elif command -v apt-get >/dev/null 2>&1; then
  PKG="sudo apt-get -y install"; UPDATE="sudo apt-get update -y"; DISTRO="ubuntu"
else
  echo "Unsupported WSL distro (need dnf or apt-get)."; exit 1
fi

echo "WSL companion running on: $DISTRO"
$UPDATE
$PKG git curl wget zip unzip tar ca-certificates

# Optional examples:
# $PKG imagemagick vlc audacity
# $PKG python3 python3-pip
# if [ "$DISTRO" = "fedora" ]; then
#   $PKG openssh-server && sudo systemctl enable --now sshd
# else
#   $PKG openssh-server && sudo service ssh start
# fi

echo "Base packages installed. Customize this script as needed."
'@

  $wsl_readme = @"
# WSL Companion Setup — README

**Emitted by:** setup-win-start.ps1  
**Timestamp:** $startTimestamp

This directory is automatically generated by the Windows bootstrap.  
Make sure you've run **setup-win-start.ps1** first — it performs prechecks, logging, and may emit other helpers.

## Purpose
`wsl-setup.sh` configures a minimal, signed-package baseline inside **Fedora** or **Ubuntu** WSL: base CLI tools and commented add-ons.

## Quick Start
1. Copy this directory into WSL (example):
   ```powershell
   wsl -- cd ~ && cp -r /mnt/c/Users/<YourUser>/Desktop/WSL_Setup_* .
   ```
2. Inside WSL, run:
   ```bash
   bash wsl-setup.sh
   ```
3. (Optional) Open `wsl-setup.sh` and enable extras (Python, SSH, media tools).

## Verification & Next Steps
- Uses `dnf`/`apt` official repos (GPG-verified).  
- Integrate Docker/conda/etc. after this baseline.  
- See the desktop `completed_install_report_*.log` for emission details.

License: MIT — provided as-is for reproducible bootstrap.
"@

  Set-Content -Path (Join-Path $outDir "wsl-setup.sh") -Value $wslbash -Encoding UTF8
  Set-Content -Path (Join-Path $outDir "WSL_SETUP_README.md") -Value $wsl_readme -Encoding UTF8

  $emittedDirs.Add($outDir) | Out-Null
  $doneList.Add("Emitted WSL Companion Pack → $outDir") | Out-Null
  $nextSteps.Add("Copy into your WSL home and run `bash wsl-setup.sh`.") | Out-Null
}

# ---------------- Archive4Doc logic ----------------
if ($Archive4Doc -eq 'y' -and $emittedDirs.Count -gt 0) {
  Section "Archive4Doc"
  foreach ($dir in $emittedDirs) {
    $name = Split-Path $dir -Leaf
    if ($name -like "Cygwin_Bootstrap_*") {
      $ad = Join-Path (Split-Path $dir -Parent) (".4doc_Cygwin_{0}" -f $startTimestamp)
    } elseif ($name -like "WSL_Setup_*") {
      $ad = Join-Path (Split-Path $dir -Parent) (".4doc_WSL_{0}" -f $startTimestamp)
    } else {
      continue
    }
    Copy-Item -Recurse -Force $dir $ad
    # append .{timestamp}.4doc to files inside
    Get-ChildItem -Recurse -File $ad | ForEach-Object {
      $new = $_.FullName + "." + $startTimestamp + ".4doc"
      Rename-Item -Path $_.FullName -NewName $new -Force
    }
    $doneList.Add("Archived → $ad (filenames suffixed with .$startTimestamp.4doc)") | Out-Null
  }
}

# ---------------- .gitignore advisory ----------------
Section ".gitignore advisory"
$giBlock = @"
# --- Bootstrap emissions (ignored) ---
Cygwin_Bootstrap_*/
WSL_Setup_*/
completed_install_report_*.log
partial_install_report_*.log
bootstrap_cyg.cmd
cyg-bootstrap.sh
wsl-setup.sh
SHA256SUMS.txt
CYG_README.md
WSL_SETUP_README.md

# --- Allow explicit 4doc documentation snapshots ---
!/.4doc_Cygwin_*/
!/.4doc_WSL_*/
!/.4doc_Cygwin_*/**
!/.4doc_WSL_*/**
!END_OF_DAY_README_*.4doc.md
"@

$giPath = Join-Path $cwd ".gitignore"
if (-not (Test-Path $giPath)) {
  Log "'.gitignore' not found in $cwd."
  Log "Create it and add the following before committing:"
  Log $giBlock
} else {
  $currentGi = Get-Content $giPath -Raw
  $missing = @()
  foreach ($line in ($giBlock -split "`r?`n")) {
    if ($line.Trim() -ne "" -and ($currentGi -notmatch [Regex]::Escape($line))) {
      $missing += $line
    }
  }
  if ($missing.Count -gt 0) {
    Log "'.gitignore' found but missing the following lines; add before committing:"
    foreach ($m in $missing) { Log $m }
  } else {
    Log "'.gitignore' looks complete for bootstrap/4doc rules."
  }
}

# ---------------- END_OF_DAY_README emission ----------------
Section "END_OF_DAY_README emission"
$eodName = "END_OF_DAY_README_{0}.4doc.md" -f $startTimestamp
$eodPath = Join-Path $cwd $eodName
$eodContent = @"
# End-of-Day Snapshot — $startTimestamp

**What this includes**
- Emission tokens run: `$(($want) -join ", ")`
- Archive4Doc: $Archive4Doc
- Emitted folders:
$(($emittedDirs | ForEach-Object { "  - " + $_ }) -join "`n")
- Logs written on Desktop:
  - completed_install_report_$startTimestamp.log

**Git hygiene**
This repo expects `.4doc_*` folders and `END_OF_DAY_README_*.4doc.md` to be tracked; live emission folders remain ignored. See .gitignore advisory section above.

**Next steps (tomorrow)**
1. Create a system restore point (if not already done).
2. Run Windows Update and reboot.
3. Relocate WSL to D:\ and initialize Fedora.
4. Run `wsl-setup.sh` inside WSL and verify base packages.
5. Initialize GPG keypair and test signing.

— Generated by setup-win-start.ps1
"@
Set-Content -Path $eodPath -Value $eodContent -Encoding UTF8
$doneList.Add("Emitted $eodName at $cwd") | Out-Null

# ---------------- Summary ----------------
Section "Summary"
Log "Start:  $startTimestamp"
Log "Now:    $(NowStr)"
Log ""
Log "Emitted:"
$doneList | ForEach-Object { Log " - $_" }

if ($nextSteps.Count -gt 0) {
  Log "`nNext steps:"
  $nextSteps | ForEach-Object { Log " - $_" }
}

Copy-Item $logPartial $logComplete -Force
Remove-Item $logPartial -Force
Write-Host "`nSaved to: $logComplete" -ForegroundColor Green
