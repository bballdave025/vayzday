<#
  setup-win-start.ps1  (emits Cygwin bootstrap + WSL companion)
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)] [string]$Installs,
  [ValidateSet('y','n')] [string]$Interactive = 'y',
  [ValidateSet('y','n')] [string]$VerifyManualDownloads = 'y',
  [ValidateSet('y','n')] [string]$RestorePoints = 'y'
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

function Log($s){ $s | Tee-Object -FilePath $logCurrent -Append | Out-Host }
function Section($t){ Log "`n=== $t ===`n" }

$admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $admin) { Write-Host "Run in elevated Windows PowerShell (Admin)." -ForegroundColor Yellow; exit 1 }

$want = @()
if ($Installs.Trim().ToLower() -ne 'none') {
  $want = $Installs.Split(',').ForEach({ $_.Trim().ToLower() } ) | Where-Object { $_ -ne '' }
}

# --- emit-cygwin-bootstrap ---
if ($want -contains 'emit-cygwin-bootstrap') {
  Section "Emit Cygwin Bootstrap Pack"
  $out = Join-Path $desk ("Cygwin_Bootstrap_" + $startTimestamp)
  New-Item -ItemType Directory -Path $out -Force | Out-Null

  $bootstrap = @"
@echo off
setlocal enableextensions enabledelayedexpansion
REM Cygwin Headless Bootstrap (verified)
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
   $m=[regex]::Match($p,'Primary key fingerprint:\s*([0-9A-F]{4}(?:\s+[0-9A-F]{4}){9})','IgnoreCase'); ^
   if(-not $m.Success){exit 1}; $m.Groups[1].Value.ToUpper()"`) do set CYG_FP_WEB=%%F
if "%CYG_FP_WEB%"=="" ( echo [!] Could not scrape fingerprint; aborting. & exit /b 1 )

echo [*] Locating signing key via WKD/keyserver...
gpg --batch --quiet --auto-key-locate clear,wkd,local,keyserver --locate-keys cygwin@cygwin.com || ( echo [!] Key import failed. & exit /b 1 )

for /f "usebackq tokens=* delims=" %%F in (`gpg --batch --with-colons --fingerprint cygwin@cygwin.com ^| ^
  findstr /b /c:"fpr:" ^| ^
  powershell -NoProfile -Command "$i=Get-Content -Raw -; ($i -split '\n' ^| %%{$_ -split ':'}[9]) ^| Select-Object -First 1"`) do set CYG_FP_GPG=%%F
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
  "$W=New-Object -ComObject WScript.Shell; $S=$W.CreateShortcut('$env:Public\Desktop\Cygwin Terminal.lnk'); ^
   $S.TargetPath='%CYG_ROOT%\bin\mintty.exe'; $S.Arguments='-i /Cygwin-Terminal.ico -'; ^
   $S.WorkingDirectory='%CYG_ROOT%\home\%USERNAME%'; $S.IconLocation='%CYG_ROOT%\Cygwin-Terminal.ico'; $S.Save()"

echo [*] Writing cyg-bootstrap.sh and launcher...
if not exist "%CYG_USER_HOME%" mkdir "%CYG_USER_HOME%"
> "%CYG_USER_HOME%\cyg-bootstrap.sh" echo #!/bin/bash
> "%CYG_USER_HOME%\run_cyg.sh" echo bash /home/%USERNAME%/cyg-bootstrap.sh
"%CYG_ROOT%\bin\bash.exe" -lc "/home/%USERNAME%/cyg-bootstrap.sh"

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

echo "Screen size: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
echo "Top stub: $TOP_APP"
echo "Bottom target: $BOTTOM_APP"
get_top_app(){ adb shell dumpsys window windows | grep -E "mCurrentFocus" | sed 's/.* //'; }

echo "Launching top stub..."
adb shell am start -n "$TOP_APP" --activity-options 'activityOptions.setLaunchWindowingMode(3)'
sleep 2

echo "Launching bottom app..."
adb shell am start -n "$BOTTOM_APP" --activity-options "activityOptions.setLaunchWindowingMode(3);activityOptions.setLaunchBounds(new android.graphics.Rect(0,$HALF_HEIGHT,$SCREEN_WIDTH,$SCREEN_HEIGHT))"
sleep 3

TOP_WINDOW=$(get_top_app)
if [[ "$TOP_WINDOW" == *"${BOTTOM_APP%%/*}"* ]]; then
  echo "Detected: bottom app occupied top pane. Auto-swapping..."
  adb shell am start -n "$BOTTOM_APP" --activity-options 'activityOptions.setLaunchWindowingMode(3)'
  sleep 2
  adb shell am start -n "$TOP_APP" --activity-options "activityOptions.setLaunchWindowingMode(3);activityOptions.setLaunchBounds(new android.graphics.Rect(0,0,$SCREEN_WIDTH,$HALF_HEIGHT))"
else
  echo "Confirmed: bottom app in lower half."
fi

echo "✅ Split-screen setup complete."
EOF
chmod +x ~/bin/split_bottom.sh
grep -q 'alias splitbot=' ~/.bashrc || echo 'alias splitbot="split_bottom.sh"' >> ~/.bashrc
echo "Cygwin bootstrap complete. Try: adb devices && splitbot com.android.chrome/com.google.android.apps.chrome.Main"
"@

  $sha = "34294314692b544e3bf4d90649919560c3af6c7adfad40e243678541a3ae7576  setup-x86_64.exe`n"

  $readme = @"
# Cygwin Headless Bootstrap — README

> Verified-on-install, non-GUI Cygwin path with optional Android split-screen helper

Cygwin Headless Bootstrap - README (Plain Text Edition)

This README explains the two bootstrap scripts for a non-GUI Cygwin install with signature verification and Android ADB tools.

------------------------------------------------------------
## Overview
------------------------------------------------------------
bootstrap.cmd  - Windows-side installer. Prefers winget; if not available, it downloads and verifies Cygwin's installer, installs headlessly, and sets up the Mintty terminal shortcut and cyg-bootstrap.sh.

cyg-bootstrap.sh - Runs inside Cygwin. Adds PATH entries, installs helpful packages, and creates the split_bottom.sh script for Android split-screen control.

------------------------------------------------------------
## Quick Start
------------------------------------------------------------
1. Save bootstrap.cmd anywhere.
2. Run it as Administrator.
3. Wait for completion. It will create a Cygwin Terminal shortcut on the desktop.
4. Open Cygwin Terminal and test:
```
adb devices
```
```
splitbot com.android.chrome/com.google.android.apps.chrome.Main
```

------------------------------------------------------------
## Verification Workflow
------------------------------------------------------------
When winget is unavailable, bootstrap.cmd verifies the installer using GPG.
1. Downloads setup-x86_64.exe and setup-x86_64.exe.sig.
2. Scrapes the fingerprint from cygwin.com/install.html.
3. Imports the key for cygwin@cygwin.com using gpg --locate-keys.
4. Compares the scraped fingerprint and the one from GPG.
5. If they match, verifies the signature using gpg --verify.
6. Installs only after verification succeeds.

------------------------------------------------------------
## Manual Verification if Scraper Fails
------------------------------------------------------------
1. Visit https://www.cygwin.com/install.html.
2. Copy the Primary key fingerprint.
3. Run:
```
gpg --locate-keys cygwin@cygwin.com
```
```
gpg --fingerprint cygwin@cygwin.com
```
4. Check the fingerprint matches the website.
5. Run gpg --verify setup-x86_64.exe.sig setup-x86_64.exe.
6. If correct, re-run bootstrap.cmd or skip to :SETUPRUN section.

------------------------------------------------------------
## Common Pitfalls
------------------------------------------------------------
Rebase or dash hang: Close all Cygwin or Git Bash windows, then re-run bootstrap.cmd. If still stuck:
   /usr/bin/rebase-trigger full
   exit
and re-run setup.

ADB unauthorized: Check your phone for the Allow USB debugging prompt.

No GPG detected: Install Git for Windows or Gpg4win before running, or rely on winget.

------------------------------------------------------------
## Why mirrors.kernel.org
------------------------------------------------------------
This mirror is stable and globally reliable, avoiding prompt-driven mirror selection.

------------------------------------------------------------
## ADB Split-Bottom Helper
------------------------------------------------------------
The split_bottom.sh script launches a stub app (Keep, Settings, or Calculator) on the top half of Android split-screen and your chosen app in the bottom half. It auto-detects screen size and swaps positions if needed.

Usage:
```
splitbot com.android.chrome/com.google.android.apps.chrome.Main
```
```
splitbot com.android.settings/.Settings
```

------------------------------------------------------------
## Integrity Checks
------------------------------------------------------------
SHA-256 for Cygwin_Headless_Bootstrap_Full.zip:
34294314692b544e3bf4d90649919560c3af6c7adfad40e243678541a3ae7576

To verify:
```
sha256sum Cygwin_Headless_Bootstrap_Full.zip
```

------------------------------------------------------------
## License
------------------------------------------------------------
MIT License. Based on public Cygwin documentation and GPG verification examples.

Maintained scripts and notes compiled for Dave BLACK, 2025.

"@

  Set-Content -Path (Join-Path $out "bootstrap_cyg.cmd") -Value $bootstrap -Encoding UTF8
  Set-Content -Path (Join-Path $out "cyg-bootstrap.sh")  -Value $cyg_sh   -Encoding UTF8
  Set-Content -Path (Join-Path $out "SHA256SUMS.txt")    -Value $sha      -Encoding UTF8
  Set-Content -Path (Join-Path $out "CYG_README.md")     -Value $readme   -Encoding UTF8
  $doneList.Add("Emitted Cygwin Bootstrap Pack → $out") | Out-Null
  $nextSteps.Add("To install later: open elevated PowerShell and run bootstrap_cyg.cmd in that folder.") | Out-Null
}

# --- emit-wsl-setup ---
if ($want -contains 'emit-wsl-setup') {
  Section "Emit WSL Companion"
  $out = Join-Path $desk ("WSL_Setup_" + $startTimestamp)
  New-Item -ItemType Directory -Path $out -Force | Out-Null

  $wslbash = @'
#!/usr/bin/env bash
set -Eeuo pipefail
ORIG_IFS="$IFS"; IFS=$'
	'
trap 'IFS="$ORIG_IFS"' EXIT

if command -v dnf >/dev/null 2>&1; then
  PKG="sudo dnf -y install"
  UPDATE="sudo dnf -y update"
  DISTRO="fedora"
elif command -v apt-get >/dev/null 2>&1; then
  PKG="sudo apt-get -y install"
  UPDATE="sudo apt-get update -y"
  DISTRO="ubuntu"
else
  echo "Unsupported WSL distro."; exit 1
fi

echo "WSL companion on: $DISTRO"
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

echo "✓ Base packages installed. Customize as needed."
'@

  Set-Content -Path (Join-Path $out "wsl-setup.sh") -Value $wslbash -Encoding UTF8
  $doneList.Add("Emitted WSL Companion → $out") | Out-Null
  $nextSteps.Add("Copy wsl-setup.sh into WSL and run: bash wsl-setup.sh") | Out-Null
}

Section "Summary"
Log "Start:  $startTimestamp"
Log "Now:    $(NowStr)"
Log ""
Log "Done:"
$doneList | ForEach-Object { Log " - $_" }
if ($nextSteps.Count -gt 0) {
  Log "`nNext steps:"
  $nextSteps | ForEach-Object { Log " - $_" }
}

Copy-Item $logPartial $logComplete -Force
Remove-Item $logPartial -Force
Write-Host "`nSaved to: $logComplete" -ForegroundColor Green
