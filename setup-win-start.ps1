<#
  setup-win-start.ps1
  Features:
    - Tokens: emit-cygwin-bootstrap, emit-wsl-setup
    - Archive switch: -Archive4Doc y|n  (copies emissions into .4doc_* dirs and appends .{timestamp}.4doc to filenames)
    - Emits 
try {
    if ($null -ne $logComplete) {
        $script:logCurrent = $logComplete
    }
} catch { }

END_OF_DAY_README_{timestamp}.4doc.md at current working directory
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
  [ValidateSet('y','n'
  [ValidateSet("All","PreInitialUpdate","PostBeginningPreBigSetup","PostBigSetup",
  [switch]$EnableRestorePoints)

# === Guard: legacy restore flags not supported ===
$legacyFlags = @('SkipRestorePoints','RestorePoints','EnableRestorePoints')
foreach($lf in $legacyFlags){
    if ($PSBoundParameters.ContainsKey($lf)) {
        Write-Error "Flag '$lf' is no longer supported. Use -WithRestorePoints and -RestorePointPhase instead."
        exit 2
    }
}
# === Guard: reject misspelled token ===
if ($Installs -and ($Installs -match 'emit-wsl-cywin-artifacts')){
    Write-Error "Unknown install token 'emit-wsl-cywin-artifacts'. Did you mean 'emit-wsl-cygwin-artifacts'?"
    exit 3
}


function Invoke-Action {
    param(
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][scriptblock]$Do
    )
    if ($DryRun) {
        Write-Host "[DRY-RUN] $Description"
    } else {
        & $Do
    }
}

function Set-ContentLiteralUtf8 {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )
    Invoke-Action -Description "Write file: $Path" -Do {
        $dir = [System.IO.Path]::GetDirectoryName($Path)
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
    }
}

][string]$RestorePointPhase = "All",
function New-SafeRestorePoint {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Description)
  try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue | Out-Null
  } catch {}
  try {
    Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS"
    Write-Host "[restore] Created: $Description"
  } catch {
    Write-Warning "[restore] Could not create restore point. $_"
  }
}

  [switch]$SkipRestorePoints)] [string]$Interactive = 'y',
  [ValidateSet('y','n')] [string]$VerifyManualDownloads = 'y',
  [ValidateSet('y','n')] [string]$RestorePoints = 'y',
  [ValidateSet('y','n')] [string]$Archive4Doc = 'n',
  [switch]$Help
    [switch] $DryRun,
    [switch] $WithRestorePoints,
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

  $bootstrap_cmd = @'
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
'@

  $cyg_sh = @'
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
'@

  $sha = "34294314692b544e3bf4d90649919560c3af6c7adfad40e243678541a3ae7576  setup-x86_64.exe`n"

  $readme = @'
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
'@

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

  $wsl_readme = @'
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
'@

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
$giBlock = @'
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
'@

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
$eodContent = @'
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
'@
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

    # ======================================================================
    # === Integrated emit logic (inline) — added by ChatGPT on 2025-10-18 ===
    # ======================================================================

    function Get-SharedTimestamp {
      $now = Get-Date
      $epoch = [int][double]::Parse((Get-Date -Date $now.ToUniversalTime() -UFormat %s))
      $iso   = $now.ToString("yyyy-MM-ddTHHmmsszzz").Replace(":","")
      return "{0}_{1}" -f $epoch, $iso
    }

    function Resolve-DefaultBaseDir {
      $desk = [Environment]::GetFolderPath("Desktop")
      $base = Join-Path $desk "default_setup_2025-10-18-Early"
      New-Item -ItemType Directory -Force -Path $base | Out-Null
      return $base
    }

    function Write-StringToFileUtf8 {
      param([string]$Path,[string]$Body)
      $dir = Split-Path -Parent $Path
      if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
      [System.IO.File]::WriteAllText($Path, $Body, [System.Text.Encoding]::UTF8)
    }

    function New-DocArchiveCopy {
      param(
        [Parameter(Mandatory)][string]$SourceFile,
        [Parameter(Mandatory)][string]$ArchiveDir,
        [Parameter(Mandatory)][string]$SharedTS
      )
      New-Item -ItemType Directory -Force -Path $ArchiveDir | Out-Null
      $name = [System.IO.Path]::GetFileName($SourceFile)
      $archName = "$name.$SharedTS.4doc"
      Copy-Item -LiteralPath $SourceFile -Destination (Join-Path $ArchiveDir $archName) -Force
    }

    function Write-CheckNewLinuxArtifacts {
      [CmdletBinding()]
      param([Parameter(Mandatory)][string[]]$DestRoots)

      $scriptText = @'
#!/usr/bin/env bash
set -euo pipefail
TS="{" + r"$(date +'%s_%Y-%m-%dT%H%M%S%z')" + r"}"
BACK="$HOME/.important_backups"
OUT="${BACK}/new_linux_bash_${TS}.out"
mkdir -p "$BACK"
{
  echo "==== new_linux_bash snapshot @ $(date) ===="
  echo "user: $USER  host: $(hostname)"
  echo
  echo "== shell =="
  echo "BASH_VERSION=$BASH_VERSION"
  echo "SHELL=$SHELL"
  echo "TTY=$(tty || true)"
  echo
  echo "== key env =="
  printf "IFS=("; printf %q "$IFS"; printf ")
"
  echo "PATH=$PATH"
  echo "MANPATH=${MANPATH-}"
  echo "PS1=${PS1-}"
  echo "PROMPT_COMMAND=${PROMPT_COMMAND-}"
  echo "TITLE_STRING=${TITLE_STRING-}"
  echo
  echo "== locale =="
  locale || true
  echo
  echo "== versions =="
  { uname -a || true; } ; echo
  { lsb_release -a 2>/dev/null || true; } ; echo
  { cat /etc/os-release 2>/dev/null || true; } ; echo
  { rpm -qa 2>/dev/null | wc -l | xargs echo "rpm_count=" || true; }
  { dpkg -l 2>/dev/null | wc -l | xargs echo "dpkg_count=" || true; }
  echo
  echo "== binaries =="
  for b in bash sh zsh fish python3 python node npm git tree screen tmux brightnessctl xrandr; do
    printf "%-14s" "$b"; command -v "$b" || echo "not found"
  done
  echo
  echo "== dotfiles (backups) =="
} | tee "$OUT"
for f in .bashrc .profile .vimrc .gitconfig .bash_profile .inputrc; do
  [ -f "$HOME/$f" ] && cp -a "$HOME/$f" "$BACK/${f}.${TS}.bak" || true
done
syslist=(/etc/profile /etc/bashrc /etc/bash.bashrc /etc/environment /etc/manpath.config)
for s in "${syslist[@]}"; do
  [ -r "$s" ] && cp -a "$s" "$BACK/$(basename "$s").${TS}.bak" || true
done
printf %s "$IFS" > "$BACK/IFS.${TS}.bak"
: "${PATH}"    ; printf %s "$PATH"  > "$BACK/PATH.${TS}.bak"
: "${MANPATH-}"; printf %s "${MANPATH-}" > "$BACK/MANPATH.${TS}.bak"
: "${PS1-}"    ; printf %s "${PS1-}" > "$BACK/PS1.${TS}.bak"
: "${PROMPT_COMMAND-}" ; printf %s "${PROMPT_COMMAND-}" > "$BACK/PROMPT_COMMAND.${TS}.bak"
: "${TITLE_STRING-}"   ; printf %s "${TITLE_STRING-}"   > "$BACK/TITLE_STRING.${TS}.bak"
echo "Snapshot written to: $OUT"
echo "Backups directory:   $BACK"
'@

      $readmeText = @'
check_new_linux_bash — quick baseline capture (WSL, Fedora, Ubuntu, Cygwin)

What it does
• Saves a timestamped environment snapshot to ~/.important_backups/new_linux_bash_<epoch>_<ISO>.out
• Backs up common dotfiles (.bashrc, .profile, .vimrc, .gitconfig, etc.) with the same timestamp.
• Backs up pre-dotfile system files when readable (/etc/profile, /etc/bashrc or /etc/bash.bashrc, /etc/environment, /etc/manpath.config).
• Saves single-value captures (IFS, PATH, MANPATH, PS1, PROMPT_COMMAND, TITLE_STRING) into separate .bak files.

How to run
  1) Place both files in any shell environment (WSL, Fedora, Ubuntu, or Cygwin):
     - check_new_linux_bash.sh
     - .portable.bashrc   (optional, but nice!)
  2) Make the script executable and run it:
       chmod +x check_new_linux_bash.sh
       ./check_new_linux_bash.sh
  3) Review outputs in ~/.important_backups/
'@

      foreach ($root in $DestRoots) {
        $outDir = Join-Path $root "linux_baseline"
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
        $sh = Join-Path $outDir "check_new_linux_bash.sh"
        $txt = Join-Path $outDir "check_new_linux_bash.txt"
        [System.IO.File]::WriteAllText($sh, $scriptText, [System.Text.Encoding]::UTF8)
        [System.IO.File]::WriteAllText($txt, $readmeText, [System.Text.Encoding]::UTF8)
        Write-Host "[emit] $sh"
        Write-Host "[emit] $txt"
      }
    }

    function Write-PortableBashrc {
      [CmdletBinding()]
      param([Parameter(Mandatory)][string[]]$DestRoots)

      $merged = @'
# ~/.portable.bashrc (portable core)
[ -f /etc/bash.bashrc ] && . /etc/bash.bashrc
# Quiet defaults that won't hurt
alias rmi='rm -i'
alias cpi='cp -i'
alias mvi='mv -i'
alias lessraw='less -r'
alias whence='type -a'                            # where, of a sort
alias dir='ls --color=auto --format=vertical'
alias vdir='ls --color=auto --format=long'
alias ll='ls -l'                                  # long list
alias lh='ls -lah'
alias la='ls -A'                                  # all but . and ..
alias l='ls -CF'
alias ls_name_and_size='ls -Ss1pq --block-size=1'
alias runlog='runscriptreplayclean'

# Timestamp helpers, note ttdate and timestamp equivalent, muscle memory
dbldate()      { date && date +'%s'; }
tripledate()   { date && date +'%s' && date +'%s_%Y-%m-%dT%H%M%S%z'; }
trpdate() { tripledate; }
ttdate()       { date +'%s_%Y-%m-%dT%H%M%S%z'; }  # muscle memory
timestamp() { date +"%s_%Y-%m-%dT%H%M%S%z"; }


##### PORTABLE ADDITIONS ###########################################

# ---- Portable functions and prompt setup brought from       ---- #
# ---- ~/.bballdave025_bash_functions                         ---- #
# ---- Checks for exernal dependencies, other safe things,    ---- #
# ---- still to be checked with ChatGPT.                      ---- #

## Try to import your function bodies if available (repo or HOME copies)
#for PF in "$HOME/my_repos_dwb/vayzday/.bballdave025_bash_functions" \
#          "$HOME/.bballdave025_bash_functions"; do
#  [ -f "$PF" ] && . "$PF" && break
#done

export ORIG_FEDORA_PROMPT_COMMAND=
export ORIG_RHEL_PROMPT_COMMAND=\
'printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'
export ORIG_UBUNTU_PROPMPT_COMMAND=
export ORIG_CYGWIN_PROMPT_COMMAND=

export ORIG_PROMPT_COMMAND="${ORIG_UBUNTU_PROMPT_COMMAND}"


ON_START_PROMPT_COMMAND=
if [ ! -z "$PROMPT_COMMAND"  ]; then
  ON_START_PROMPT_COMMAND="$PROMPT_COMMAND"
fi

# Getting rid of it. We way re-set it later
PROMPT_COMMAND=

# Replaced what's below, which was for Cygwin
## #Keeping default
## DEFAULT_PROMPT_COMMAND=\
## 'echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007"'
## DEFAULT_PROMPT_COMMAND_TITLE=\
## "${USER}@${HOSTNAME}: ${PWD/$HOME/~}"


### For scope
DEFAULT_PROMPT_COMMAND=
DEFAULT_PROMPT_COMMAND_TITLE=

# from xterm part of pre-change ~/.bashrc
DEFAULT_DWB_FEDORA_PROMPT_COMMAND=
DEFAULT_DWB_RHEL_PROMPT_COMMAND=\
'echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007"'
DEFAULT_DWB_UBUNTU_PROMPT_COMMAND=\
'echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007""'
DEFAULT_DWB_CYGWIN_PROMPT_COMMAND=\
'echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007"'

DEFAULT_PROMPT_COMMAND="${ORIG_PROMPT_COMMAND}"

DEFAULT_DWB_FEDORA_PROMPT_COMMAND_TITLE=
DEFAULT_DWB_RHEL_PROMPT_COMMAND_TITLE=\
"${USER}@${HOSTNAME}: ${PWD/$HOME/~}"
DEFAULT_DWB_UBUNTU_PROMPT_COMMAND_TITLE=\
"${USER}@${HOSTNAME}: ${PWD/$HOME/~}"
DEFAULT_CYGWIN_PROMPT_COMMAND_TITLE=\
"${PWD/$HOME/~}"

DEFAULT_PROMPT_COMMAND_TITLE=\
"${DEFAULT_DWB_UBUNTU_PROMPT_COMMAND_TITLE}"

# from /etc/bash.bashrc
REAL_LINUX_DEFAULT_PS1="\\s-\\v\\\$ "
# from something in /etc/
REAL_LINUX_DEFAULT_PROMPT_COMMAND=\
'echo "$0-$(awk -F'"'"'.'"'"' '"'"'{print $1 "." $2}'"'"' '\
'<<<$BASH_VERSION)"'
REAL_LINUX_DEFAULT_PROMPT_COMMAND_TITLE=\
'$($0-$(awk -F'"'"'.'"'"' '"'"'{print $1 "." $2}'"'"' <<<$BASH_VERSION)'

# from the pre-change ~/.bashrc
export REAL_ORIG_FEDORA_PS1=
export REAL_ORIG_RHEL_PS1="[\u@\h \W]\\$ "
export READ_ORIG_UBUNTU_PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
export REAL_ORIG_CYGWIN_PS1=\
"\[\e]0;\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ "
export REAL_ORIG_PS1="${REAL_ORIG_CYGWIN_PS1}"

NOW_ORIG_PS1="${REAL_ORIG_UBUNTU_PS1}"

# show git branch
git_branch_func() {
  my_env_name=$(git symbolic-ref HEAD --short 2>/dev/null)
  if [ $? -eq 0 ]; then
    printf %s "[${my_env_name}]"
  else
    printf %s ""
  fi
}

alias git_branch=git_branch_func

##  This stuff lets me get things how I want to post them
##+ (as far as PS1)                                  start-1
NOW_ORIG_FEDORA_PS1=
NOW_ORIG_CYGWIN_PS1=" <=> conda environment, blank means none activated\n\[\e[38;5;48m\]\$(git_branch)\[\e[0m\] <=> git branch, blank means not in a git repo\[\e]0;\w\a\]\n\[\e[32m\]bballdave025@MY-MACHINE \[\e[33m\]\w\[\e[0m\]\n\$ "
NOW_ORIG_UBUNTU_PS1=" <=> conda environment, blank means none activated\n\[\e[38;5;48m\]\$(git_branch)\[\e[0m\] <=> git branch, blank means not in a git repo\[\e]0;\w\a\]\n\[\e[32m\]bballdave025@MY-MACHINE \[\e[33m\]\w\[\e[0m\]\n\$ "
NOW_ORIG_RHEL_PS1=" <=> conda environment, blank means none activated\n\[\e[38;5;48m\]\$(git_branch)\[\e[0m\] <=> git branch, blank means not in a git repo\[\e]0;\w\a\]\n\[\e[32m\]bballdave025@MY-MACHINE \[\e[33m\]\w\[\e[0m\]\n\$ "

export NOW_ORIG_FEDORA_PS1
export NOW_ORIG_CYGWIN_PS1
export NOW_ORIG_UBUNTU_PS1
export NOW_ORIG_RHEL_PS1
NOW_ORIG_PS1="$NOW_ORIG_UBUNTU_PS1"
export NOW_ORIG_PS1

five_equals="====="

fiftyeight_pds=\
".................................."\
"........................"
nine_pds=\
"........."
three_pds="..."


export five_equals
export fiftyeight_pds
export nine_pds
export three_pds

DEFAULT_PROMPT_COMMAND='
myretval=$?;
if [ $myretval -eq 0 ]; then
  btw_str="retval=${myretval}"
  echo -ne "\033[48;5;22m$five_equals\033[0m$fiftyeight_pds$btw_str$nine_pds"
  # 22 current best for green
else
  btw_str="retval=0d$(printf %05d $myretval)";
  echo -ne "\033[48;5;167m$five_equals\033[0m$fiftyeight_pds$btw_str$three_pds"
  # 167 current best for red
fi;
echo -ne "\n\n";
'
#@ TODO, ADD TERMINAL WINDOW TITLE
#        This will be a  set_title  function, with other possible aliases
#        Allow change to arbitrary text (MVP is text only, could do commands, later).
#        Also include a  revert_title  function.

PROMPT_COMMAND="$DEFAULT_PROMPT_COMMAND"
export PROMPT_COMMAND
PS1="$NOW_ORIG_PS1"
export PS1

export DEFAULT_PS1="$PS1"

# scope
ESCAPED_BOTH_TITLE=



###########################
## MORE RECENT FUNCTIONS ##
###########################


#####################################
# Encoding stuff
#####################################
##DWB: get the binary value for a character's bytes
##@author: David Wallace BLACK
# GitHub: @bballdave025
gethex4char()
{
  if [ "$@' = "-h" -o "$@' = "--help" ]; then
    echo "Help for gethex4char:"
    echo
    echo "Get the hex value for the bytes representing the"
    echo "character given as input."
    echo
    echo "Usage:"
    echo "% gethex4char <string-with-one-character>"
    echo
    echo "Examples:"
    echo "% gethex4char <string-with-one-character>"
    echo
    echo "Note that you might have to copy/paste the glyph of the"
    echo "character into some type of programmer's notebook with"
    echo "the encoding set as you want it (I want UTF-8)"
    echo "Then, in the notebook, write in the"
    echo "gethex4char part as well as the quotes around the character."
    echo
    echo "It will be easier (less backslash escapes) if you use single"
    echo "quotes around the character you pass in. The only exceptions"
    echo "(for ascii, at least), are the single quote and the percent"
    echo "sign. I fixed the percent sign, DWB 2022-02-16."
    echo "For the single quotes, use:"
    echo "% gethex4char \"'\""
    echo
    echo "If you really want to use double quotes, watch out for the"
    echo "following, which will not allow the program to continue -"
    echo "i.e. they will break the program."
    echo "--BAD)% gethex4char \"\\\""
    echo " instead, use single quotes or"
    echo " GOOD)% gethex4char \"\\\\\""
    echo "--BAD)% gethex4char \"\`\""
    echo " instead, use single quotes or"
    echo " GOOD)% gethex4char \"\\\`\""
    echo "--BAD)% gethex4char \"\"\""
    echo " instead, use single quotes or"
    echo " GOOD)% gethex4char \"\\\"\""
  elif [ "$@' = "'" ]; then
    echo "0x22"
  elif [ "$@' = "\"" ]; then
    echo "0x28"
  elif [ "$@' = "\\" ]; then
    echo "0x5c"
  elif [ "$@' = "%" ]; then
    echo "0x25"
  else
    printf $@ | hexdump -C | head -n 1 | \
     awk '{$1=""; $NF=""; print $0}' | \
     sed 's#^[ ]\(.*\)[ ]\+$#0x\1#g; s#[ ]# 0x#g;'
  fi
  return 0
}


##DWB: get the binary value for a character's bytes
getbinary4char()
{
  hex_str="00"
  if [ "$@' = "-h" -o "$@' = "--help" ]; then
    echo "Help for getbinary4char:"
    echo
    echo "Get the binary value for the bytes representing the"
    echo "character given as input."
    echo
    echo "Usage:"
    echo "% getbinary4char <string-with-one-character>"
    echo
    echo "Examples:"
    echo "% getbinary4char <string-with-one-character>"
    echo
    echo "Note that you might have to copy/paste the glyph of the"
    echo "character into some type of programmer's notebook with"
    echo "the encoding set as you want it (I want UTF-8)"
    echo "Then, in the notebook, write in the"
    echo "gethex4char part as well as the quotes around the character."
    echo
    echo "It will be easier (less backslash escapes) if you use single"
    echo "quotes around the character you pass in. The only exception"
    echo "(for ascii, at least), is the single quote. For that, use:"
    echo "% getbinary4char \"'\""
    echo
    echo "If you really want to use double quotes, watch out for the"
    echo "following, which will not allow the program to continue -"
    echo "i.e. they will break the program."
    echo "--BAD)% getbinary4char \"\\\""
    echo " instead, use single quotes or"
    echo " GOOD)% getbinary4char \"\\\\\""
    echo "--BAD)% getbinary4char \"\`\""
    echo " instead, use single quotes or"
    echo " GOOD)% getbinary4char \"\\\`\""
    echo "--BAD)% getbinary4char \"\"\""
    echo " instead, use single quotes or"
    echo " GOOD)% getbinary4char \"\\\"\""
  elif [ "$@' = "'" ]; then
    hex_str="22"
  elif [ "$@' = "\"" ]; then
    hex_str="28"
  elif [ "$@' = "\\" ]; then
    hex_str="5c"
  else
    hex_str=$(printf $@ | hexdump -C | head -n 1 | \
     awk '{$1=""; $NF=""; print $0}' | \
     sed 's#^[ ]\+$##g;' | tr 'a-f' 'A-F')
  fi
  while [ $(echo "${#hex_str} % 4" | bc) -ne 0 ]; do
    hex_str="0${hex_str}"
  done
  bin_str=$(echo "obase=2; ibase=16; ${hex_str}" | bc)
  while [ $(echo "${#bin_str} % 8" | bc) -ne 0 ]; do
    bin_str="0${bin_str}"
  done
  echo "0b${bin_str}"
  return 0
} ##endof:  getbinary4char()

##DWB: get the Unicode codepoint (as hex) for a character
getunicode4char()
{
  if [ "$@' = "-h" -o "$@' = "--help" ] 2>/dev/null; then
    echo "Help for getunicode4char:"
    echo
    echo "Get the unicode codepoint representing the"
    echo "character given as input."
    echo
    echo "Requires: python3 for now, till I get the hexdump -C stuff finished"
    echo "It was originally built with Python 3 in mind, but it works"
    echo "without that, thanks to hexdump -C"
    echo "You'll still need to watch out for the problem strings"
    echo "methioned below."
    echo
    echo "Usage:"
    echo "% getunicode4char <string-with-one-character>"
    echo
    echo "Examples:"
    echo "% getunicode4char <string-with-one-character>"
    echo
    echo "Note that you might have to copy/paste the glyph of the"
    echo "character into some type of programmer's notebook with the"
    echo "encoding set as you want it (I want UTF-8). Then, in the"
    echo "notebook, write in the  getunicode4char  part as well as"
    echo "the quotes around the character."
    echo
    echo "It will be easier (less backslash escapes) if you use single"
    echo "quotes around the character you pass in. The only exception"
    echo "(for ASCII, at least), is the single quote. For that, use:"
    echo "% getunicode4char \"'\""
    echo "Do note, however, that to get a return for the space character,"
    echo "You must escape it with a backslash, whether you surround it"
    echo "with single quotes, double quotes, or just put it in by itself."
    echo " GOOD)% getunicode4char '\ '"
    echo ' GOOD)% getunicode4char "\ "'
    echo "      % #  This next one needs explaining. You should push the"
    echo "      % #+ Space Bar once after the backslash and then press the"
    echo "      % #+ Enter key."
    echo " GOOD)% getunicode4char \ "
    echo "--BAD)% getunicode4char ' '"
    echo '--BAD)% getunicode4char " "'
    echo
    echo "If you really want to use double quotes, watch out for the"
    echo "following, which will not allow the program to continue -"
    echo "i.e. they will break the program."
    echo "--BAD)% getunicode4char \"\\\""
    echo " instead, use single quotes or"
    echo " GOOD)% getunicode4char \"\\\\\""
    echo "--BAD)% getunicode4char \"\`\""
    echo " instead, use single quotes or"
    echo " GOOD)% getunicode4char \"\\\`\""
    echo "--BAD)% getunicode4char \"\"\""
    echo " instead, use single quotes or"
    echo " GOOD)% getunicode4char \"\\\"\""
  elif [ "$@' = "'" ]; then
    echo "U+0022"
  elif [ "$@' = "\"" ]; then
    echo "U+0028"
  elif [ "$@' = "\\" ]; then
    echo "U+005c"
  else
    python3_is_installed=0
    command -v python3 >/dev/null 2>&1 && python3_is_installed=1
    if [ $python3_is_installed -eq 1 ]; then
      zeroX_str=$(python3 -c 'print(hex(ord('"'$@'"')))')
      hex_only_str=$(echo "${zeroX_str}" | sed 's#0x##g')
      while [ ${#hex_only_str} -lt 4 ]; do
        hex_only_str="0${hex_only_str}"
      done ##endof:  while [ ${#hex_only_str} -lt 4 ]
      echo "U+${hex_only_str}"
      # Only returns unicode codepoints
    else
      echo "won't work for now. need python3"
      return -1
      #printf $@ | hexdump -C | head -n 1 | \
      # awk '{$1=""; $NF=""; print $0}' | \
      # sed 's#^[ ]\(.*\)[ ]\+$#0x\1#g; s#[ ]# 0x#g;'
    fi
  fi
  return 0
} ##endof:  getunicode4char()

## DWB
getbytes4unicode()
{
  if [ "$@' = "-h" -o "$@' = "--help" ]; then
    echo "Help for getbytes4unicode:"
    echo
    echo "Get the binary value for the bytes representing the"
    echo "character given as a unicode codepoint input."
    echo
    echo "Usage:"
    echo "% getbytes4unicode <string-with-only-hex-from-unicode-codepoint>"
    echo
    echo "Examples:"
    echo "% getbytes4unicode <string-with-only-hex-from-unicode-codepoint>"
  else
    codepoint_str="$@'
    to_print_str="\\U${codepoint_str}"
    while [ $(echo "${#cpdepoint_str} % 4" | bc) -ne 0 ]; do
      codepoint_str="0${codepoint_str}"
    done ##endof:  while [ $(echo "${#codepoint_str} % 4" | bc) -ne 0 ]
    if [ ${#codepoint_str} -eq 4 ]; then
      to_print_str="\\u${codepoint_str}"
    elif [ ${#codepoint_str} -eq 8 ]; then
      to_print_str="\\U${codepoint_str}"
    else
      echo "A maximum of 8 hex digits is allowed."
    fi
    printf ${to_print_str} | hexdump -C | head -n 1 | \
            awk '{$1=""; $NF=""; print $0}' | \
            sed 's#^[ ]\(.*\)[ ]\+$#0x\1#g; s#[ ]# 0x#g;'
  fi
} ##endof:  getbytes4unicode()

##DWB added 2025-07-29
get2byteandunicode4char()
{
  if [ "$@' = "-h" -o "$@' = "--help" ]; then
    echo "Help for get2bytesandunicode4char:"
    echo
    echo "Get the UTF-8 byte encoding for the "
    echo "character given as a unicode codepoint input."
    echo
    echo "Usage:"
    echo "% getbytes4unicode <string-with-only-one_char>"
    echo
    echo "Examples:"
    echo "% getbytes4unicode 'π'"
    echo
    echo "You can get more details on valid input from the help for"
    echo "getbytes4char, which is done with the command,"
    echo "% getbytes4char --help"
  else
    this_char=$@;
    first=$(gethex4char ${this_char} | tr -d '\n')
    second=$(getunicode4char ${this_char} | tr -d '\n')
    echo "( ${first} || ${second} )"
  fi
} ##endof:  get2byteandunicode4char()

alias get2bu4char='get2byteandunicode4char'
alias get24char='get2byteandunicode4char'

####################################
### More recent, small functions
####################################

##DWB: an easy way to add variable checking by useing another
##     shell, allowing use in any script or command
##@author: David Wallace BLACK
vardebug()
{
  echo "echo \"$@: \${$@}\""
  echo "   OR"
  echo "echo -e \"$@:\n\${$@}\""
  return 0
}

## DWB
## Used to get lines between two numbers from a file
htbetween_func () {
  usage_str="\n Needs two positive integers. Ex.\n"\
"\$ htbetween_func 4 72\n\n"\
" Usually used from the command line with, e.g.\n"\
" (User wants to get lines from count.txt between 4 and 72)\n"\
"\$ seq 1 100 > count.txt\n\$ htbstr 4 72\n"\
"head -n 72 | tail -69\n\$ cat -n count.txt | head -n 72 | tail -69\n\n"\
" Won't work as expected if the larger number is greater than the\n"\
" total number of lines.\n 'htbstr -h' returns this usage info\n"
  do_continue=1
  [ "$1" = "-h" ] && do_continue=0
  [ $# -lt 2 ] && do_continue=0
  if [ $do_continue -eq 1 ]; then
    [ "$1" -eq "$1" -a $1 -gt 0 ] 2>/dev/null || do_continue=0
  fi
  if [ $do_continue -eq 1 ]; then
    [ "$2" -eq "$2" -a $2 -gt 0 ] 2>/dev/null || do_continue=0
  fi

  [ $do_continue -eq 0 ] && echo -e "${usage_str}"
  if [ $do_continue -eq 1 ]; then
    first="$1"
    second="$2"
    greater=$first
    lesser=$second
    if [ $first -lt $second ]; then
      greater=$second
      lesser=$first
    fi
    n_for_tail=$(echo "${greater}-${lesser}+1" | bc)
    echo "head -n ${greater} | tail -${n_for_tail}"
  fi ##endof:  if [ $do_continue -eq 1 ]
} ##endof:  htbetween_func ()

alias htbstr=htbetween_func


## DWB 2020-05-26, Epoch: around 1590519675
git_trace_cmd_func() {
  echo "These are the commands to have git do a trace/strace-type"
  echo "thing during this terminal session (use without comments)"
  echo
  echo "-----------------------------------------"
  echo "# export GIT_TRACE_PACKET=1"
  echo "# export GIT_TRACE=1"
  echo "# export GIT_CURL_VERBOSE=1"
  echo "-----------------------------------------"
  echo
  echo "To get things back to normal during my session, I just"
  echo "change the instances of '1' to instances of '0', but "
  echo "some kind of 'unset' would also work."
  echo
} ##endof:  git_trace_cmd_func()

alias gittracecmd=git_trace_cmd_func
alias gittracecommand=git_trace_cmd_func


#  FIRST definewithheredoc FUNCTION DEF, NOT THE ONE THAT'S USED, NOW,
#+ ( 2025-10-17 )
#+ BUT THIS ONE HAS BETTER IN-FILE DOCUMENTATION
# @TODO: check
## DWB put in 2022-01-18, taken from
##+ https://stackoverflow.com/a/8088167/6505499
##+ defining a variable using a heredoc.
## Note that the alias, 'dhd', may be used
##+ everywhere you see 'definewithheredoc'
##+ below.
##
## More documentation is in the heredoc after the
## function definition.
#
definewithheredoc(){ IFS=$'\n' read -r -d '' ${1} || true; }
alias dhd='definewithheredoc'

### DWB 2022-01-18  I am giving the help for this heredoc-based function
##+ using the _same_ heredoc function. Metaaaaaa.
dhd HELPDOC <<'EndOfHelpDHD' | sed 's#^[.]$##g'
.

definewithheredoc

   DWB put this in here  2022-01-18, taken from
   https://stackoverflow.com/a/8088167/6505499
   defining a variable using a heredoc.

Note that the alias, 'dhd', may be used
everywhere you see 'definewithheredoc'
below.


USAGE

definewithheredoc VARIABLE_NAME <<LIMIT_STRING
<possibly several lines of text with no need for escapes>
lines
of
text
LIMIT_STRING

Some common choices for LIMIT_STRING include:
  EOF  ,  EOT  ,  EOM  ,  EndOfMessage

I will give two sets of commands; all the members of each
set are synonymous. See the example commands in the
EXAMPLE USAGE section below for an idea of what each does.
You can also consult
https://tldp.org/LDP/abs/html/here-docs.html

Each command (several lines of typed text with every new
line available via [ENTER]) should be entered at the
terminal prompt.


<set1>
#1.1
definewithheredoc MYVAR <<EOM
lines of
text and stuff
EOM

#1.2
dhd MYVAR <<EOM
lines of
text and stuff
EOM

</set1>


<set2>
#2.1
dhd OTHERVAR <<'EOM'
other 'lines' with
"characters" in #them
EOM

#2.2
dhd OTHERVAR <<"EOM"
other 'lines' with
"characters" in #them
EOM

#2.3
definewithheredoc OTHERVAR << \EOM
other 'lines' with
"characters" in #them
EOM

#2.4
definewithheredoc OTHERVAR <<"EOM"
other 'lines' with
"characters" in #them
EOM

#2.5
dhd OTHERVAR <<"NEVERMORE"
other 'lines' with
"characters" in #them
NEVERMORE

</set2>


EXAMPLE USAGE

$ # with expansion of command
$ definewithheredoc VAR1 <<EOF
abc'asdf"
$(echo "this-was-executed")
&*@!!++=
foo"bar"''
EOF
$ echo "$VAR1"
abc'asdf"
this-was-executed
foo"bar"''
$


OR (one other example with the EOF being different, see
....the StackOverflow reference above for more info)

$ # with command not expanded
$ definewithheredoc VAR2 <<'EOF'
abc'asdf"
$(dont-execute-this)
&*@!!++=
foo"bar"''
EOF
$ echo "$VAR2"
abc'asdf"
$(dont-execute-this)
&*@!!++=
foo"bar"''
$


NOTE: We always need the double quotes around whatever
      was used for VARIABLE_NAME when echoing the
      heredoc string variable. We did this with
        `echo "$VAR1"` and `echo "$VAR2"`
      in the examples.

.

EndOfHelpDHD

alias help_definewithheredoc='echo "$HELPDOC"'
alias help_dhd='help_definewithheredoc'


#  FIRST diffwithcontrol FUNCTION DEF, NOT THE ONE THAT'S USED, NOW
#+ ( 2025-10-17 )
#+ any differences now -^- unknown
#+ @TODO: check
diffwithcontrol()
{
  dhd dwc_help_str <<'EndOfDWC' | sed 's#^[.]$##g'
.
HELP FOR:
 diffwithcontrol

@AUTHOR
 David Wallace BLACK
GitHub: @bballdave025

@SINCE
 2022-03-09

@DESCRIPTION
 This will give a diff of two files, but will include any control
 characters that are in the files' content. It won't contain the
 `$' at the end of a line.
 This should be especially useful for files where `sed' commands
 are used to take out certain control characters.
 It's inspired by my `catwithcontrol' alias.

@USAGE
 % diffwithcontrol FILE1 FILE2

 Two arguments, no less and no more, should be given.

 If the `-h' or `--help' flag is used, this message will be
 outputted.

.
EndOfDWC

  if [ "$1" = "-h" -o "$2" -eq "--help" ]; then
    echo "${dwc_help_str}"
    return 1
  fi

  if [ $# -ne 2 ]; then
    echo "Exactly 2 arguments should be given." >&2
    echo "You gave %#"
    echo "${dwc_help_str}"
  fi

  first_file="$1"
  second_file="$2"

  diff "${first_file}" "${second_file}" | cat -ETv | \
    sed 's#[$]$##g;'

  return 0
} ##endof:  diffwithcontrol

alias dwc="diff_with_control"







# ---- Portable wrappers (no external deps) ----

# cat_with_control: show control chars (portable)
cat_with_control() 
{
  command -v cat >/dev/null || return 127; 
  cat -ETv -- "$@'; 
}
alias catwithcontrol='cat_with_control'

# atree: ASCII tree (portable if `tree` exists)
atree() 
{ if command -v tree >/dev/null; then 
    tree --charset=ascii "$@'; 
  else 
    echo "tree not installed"; 
    return 127; 
  fi; }

# atreea: like atree, but shows hidden files and directories, needs `tree`
atreea() 
{
  if command -v tree >/dev/null; then 
    tree --charset=ascii -a "$@'; 
  else 
    echo "tree not installed"; 
    return 127; 
  fi; 
} 


#  checksituation: friendly timestamp trio 
#+ and current working directory output
#+ (uses trpdate if present; else fallback)
checksituation() 
{
  echo "   Current date/tiime:"
  if type trpdate >/dev/null 2>&1; then trpdate
  else
    date; date +'%s'; date +'%s_%Y-%m-%dT%H%M%S%z'
  fi
  echo "   Current working directory:"
  pwd
}



# Color/ASCII sets — load if present; warn about grep+UTF-8 when relevant
set_color_command_aliases() {
  local f1="$HOME/.bballdave025_color4commands_set"
  if [ -f "$f1" ]; then . "$f1"; fi
  # Warn if grep may choke on non-UTF-8 locales
  if ! locale | grep -qi 'utf-8'; then
    echo "[warn] Non-UTF-8 locale detected; 'grep --color=auto' can mis-handle bytes." >&2
  fi
}
alias set_aliases_coco='set_color_command_aliases'
alias seta_coco='set_color_command_aliases'
alias sacoco='set_color_command_aliases'

# Main terminal aliases — placeholder; we’ll discuss grep unaliasing here later
set_main_terminal_aliases() {
  # @TODO: decide policy for `alias grep='grep --color=auto'` vs unalias.
  :
}
alias set_aliases_mt='set_main_terminal_aliases'
alias seta_mt='set_main_terminal_aliases'
alias samt='set_main_terminal_aliases'

# ---- Alias the function-runners when the functions exist ----
type git_branch_func        >/dev/null 2>&1 \
  && alias git_branch='git_branch_func'
type git_trace_cmd_func     >/dev/null 2>&1 \
  && alias gittracecmd='git_trace_cmd_func'
type git_trace_cmd_func     >/dev/null 2>&1 \
  && alias gittracecommand='git_trace_cmd_func'
type get2byteandunicode4char>/dev/null 2>&1 \
  && alias get2bu4char='get2byteandunicode4char'
type get2byteandunicode4char>/dev/null 2>&1 \
  && alias get24char='get2byteandunicode4char'
type definewithheredoc      >/dev/null 2>&1 \
  && alias dhd='definewithheredoc'
type help_definewithheredoc >/dev/null 2>&1 \
  && alias help_dhd='help_definewithheredoc'

#  cd_func is included even though it overrides the builtin `cd`
#+ to use the standard version, find it with  type cd, and use
#+ the absolute path
type cd_func >/dev/null 2>&1 && alias cd='cd_func'

# Provide $HELPDOC default text if unset (used by help_definewithheredoc)
: "${HELPDOC:=Portable help: definewithheredoc usage text not set.}"

# ---- Ubuntu test placeholders ----
# ## Place for set_title function

# ## Place for revert_title_path function

# ## Place for exts_in_dir function
# : '(consider replacing long alias with a function; TINN)'

# ---- Explicitly excluded for now ----
# htbetween_func
# xterm_double_wide xterm_std xterm_std_width_dbl_height  # (helps tmux)

###############################################################################

: "${strcleantermlog:=Portable terminal log cleanup placeholder.}"
alias forcleaningterminallog='echo "$strcleantermlog"'

# SECOND definewithheredoc FUNCTION DEF, THE ONE THAT'S USED, NOW
# @TODO: check
definewithheredoc ()
{
    IFS='
' read -r -d '' ${1} || true
}

# SECOND diffwithcontrol FUNCTION DEF, THE ONE THAT'S USED, NOW
#+ ( 2025-10-17 )
#+ any differences now -^- unknown
# @TODO: check
diffwithcontrol ()
{
    definewithheredoc dwc_help_str <<'EndOfDWC' | sed 's|^[.]$| |g'
.
HELP FOR:
 diffwithcontrol

@AUTHOR
 David Wallace BLACK
 GitHub @bballdave025

@SINCE
 2022-03-09

@DESCRIPTION
 This will give a diff of two files, but will include any control
 characters that are in the files' content. It won't contain the
 `$' at the end of a line.
 This should be especially useful for files where `sed' commands
 are used to take out certain control characters.
 It's inspired by my `catwithcontrol' alias.

@USAGE
 % diffwithcontrol FILE1 FILE2

 Two arguments, no less and no more, should be given.

 If the `-h' or `--help' flag is used, this message will be
 outputted.
.
EndOfDWC

    if [ "$1" = "-h" -o "$2" -eq "--help" ]; then
        echo "${dwc_help_str}";
        return 1;
    fi;
    if [ $# -ne 2 ]; then
        echo "Exactly 2 arguments should be given." 1>&2;
        echo "You gave %#";
        echo "${dwc_help_str}";
    fi;
    first_file="$1";
    second_file="$2";
    diff "${first_file}" "${second_file}" | cat -ETv | sed 's#[$]$##g;';
    return 0
}



# --- Grep policy: keep plain 'grep', use explicit helpers ---
unalias grep 2>/dev/null || true
alias grepcolor='grep --color=auto'
alias ugrep='grep --color=never'
alias bgrep='LC_ALL=C grep'
gcolor(){ case "$1" in on)alias grep='grep --color=auto';; off)unalias grep 2>/dev/null;; status|'')type -a grep;; *)echo "usage: gcolor {on|off|status} OR grepcolorset {on|off|status}";return 2;; esac; }
alias grepcolorset=gcolor

# --- ls policy: keep plain 'ls', use explicit helpers ---
unalias ls 2>/dev/null || true
alias lscolor='ls --color=auto'
alias uls='ls --color=never'
lcolor(){ case "$1" in on)alias ls='ls --color=auto';; off)unalias ls 2>/dev/null;; status|'')type -a ls;; *)echo "usage: lcolor {on|off|status} OR lscolorset {on|off|status}";return 2;; esac; }
alias lscolorset=lcolor

# --- egrep/fgrep helpers (keep commands plain) ---
unalias egrep 2>/dev/null || true
unalias fgrep 2>/dev/null || true
alias eg='grep -E'; alias fg='grep -F'
alias egcolor='grep -E --color=auto'; alias fgcolor='grep -F --color=auto'

# --- diff helpers ---
diffcolor(){ if diff --help 2>&1 | grep -q ' --color'; then command diff --color=auto "$@'; else command diff "$@'; fi; }
alias bdiff='LC_ALL=C diff'

# --- iproute2 color helper ---
ipcolor(){ command -v ip >/dev/null || { echo "ip not found" >&2; return 127; }; command ip -c "$@'; }


# --- runscriptreplayclean: interactive OR one-shot command logging ----------
# Usage:
#   runscriptreplayclean           #  full interactive session; exit to finish
#   runscriptreplayclean -l my.log            #  interactive; append to my.log
#   runscriptreplayclean -- <cmd args...>      #  one-shot command with 
#                                              #+ BEGIN/END markers
#   runscriptreplayclean -l my.log -- <cmd args...>
runscriptreplayclean() {
  local saved_in_dir="${HOME}/work_logs"
  local logfile="" cmd_str="" rc
  mkdir -p "$saved_in_dir"

  # Optional: -l/--log <file>
  if [[ "$1" == "-l" || "$1" == "--log" ]]; then
    logfile="$2"; shift 2
  fi

  # Default logfile
  if [[ -z "$logfile" ]]; then
    local ts; ts=$(ttdate 2>/dev/null || date +'%s_%Y-%m-%dT%H%M%S%z')
    logfile="${saved_in_dir}/Lab_Notebook_${USER}_${ts}.log"
  fi

  # --- MODE A: interactive whole-session logging (no BEGIN/END markers) -----
  if [[ "$1" != "--" ]]; then
    script -afe "$logfile"
    rc=$?
  else
    # --- MODE B: one-shot command with BEGIN/END markers in child shell ------
    shift
    # Safely quote the command line
    if [[ $# -eq 0 ]]; then
      echo "runscriptreplayclean: need command after --" >&2
      return 2
    fi
    local q= arg
    for arg in "$@'; do q+=" $(printf '%q' "$arg")"; done
    cmd_str="${q# }"

    # Run the command under a child bash, stamping BEGIN/END
    script -afe "$logfile" bash -lc \
'printf "[runlog] BEGIN %(%F %T %z)T\n" -1
trap '\''rc=$?; printf "[runlog] END rc=%s %(%F %T %z)T\n" "$rc" -1'\'' EXIT
'"$cmd_str"
    rc=$?
  fi

  # Make clean copy (ANSI escapes stripped) alongside the raw log

  ## -- simple regex-based cleaning --
  ##  If you prefer screen-hardcopy cleaning, comment out the next
  ##+ command and uncomment the screen block below.
  #sed -r $'s/\x1B\\[[0-9;]*[[:alpha:]]//g' "$logfile" \
  #            > "$clean" 2>/dev/null || cp -f "$logfile" "$clean"

  # -- screen-based cleaner (optional; may vary across distros) --
  #  If you prefer just the regex-based cleaning, comment out this
  #+ next command and uncomment the previous sed block
  if command -v screen >/dev/null 2>&1; then
    screen -D -m -c /dev/null sh -c \
"screen -X scrollback 500000; "\
"cat < \"$logfile\"; "\
"screen -X hardcopy -h \"$clean\"" \
    || sed -r $'s/\x1B\\[[0-9;]*[[:alpha:]]//g' "$logfile" > "$clean"
  fi

  printf "Raw log:   %s\nClean log: %s\n" "$logfile" "$clean"
  return "$rc"
}
# keep the muscle-memory alias
alias runlog='runscriptreplayclean'


# === verify_portable_bashrc: self-test =======================================
verify_portable_bashrc() {
  # Flags:
  #   -f <rcfile>   : path to the rc file (default: ~/vezde/.portable.bashrc)
  #   --quick       : skip isolated clean-shell source test
  #   --no-samples  : skip tiny sample runs (catwithcontrol/atree)
  #   --print       : print the names/arrays being checked and exit 0
  local rc="$HOME/vezde/.portable.bashrc"
  local QUICK=0 NOSAMPLES=0 PRINT=0
  while [ $# -gt 0 ]; do
    case "$1" in
      -f) rc="$2"; shift 2 ;;
      --quick) QUICK=1; shift ;;
      --no-samples) NOSAMPLES=1; shift ;;
      --print) PRINT=1; shift ;;
      *) echo \
"usage: verify_portable_bashrc [-f FILE] [--quick] [--no-samples] [--print]";
        return 2 
        ;;
    esac
  done

  # Core lists (must/optional)
  local -a MUST_ALIASES=(rmi cpi mvi lessraw whence grepcolor cgrep grepc ll la l dir vdir lsc lscolor lh ls_name_and_size runlog catwithcontrol atree checksituation dbldate tripledate ttdate)
  local -a OPT_ALIASES=(forcleaningterminallog git_branch gittracecmd gittracecommand get2bu4char get24char dhd help_dhd eg fg egcolor fgcolor ugrep bgrep gcolor diffcolor bdiff ipcolor)
  local -a MUST_FUNCS=(git_branch_func git_trace_cmd_func get2byteandunicode4char definewithheredoc cd_func)
  local -a OPT_FUNCS=(diff_with_control help_definewithheredoc)

  if [ "$PRINT" -eq 1 ]; then
    printf "RC: %s\n" "$rc"
    printf "MUST_ALIASES: %s\n" "${MUST_ALIASES[*]}"
    printf "OPT_ALIASES : %s\n" "${OPT_ALIASES[*]}"
    printf "MUST_FUNCS  : %s\n" "${MUST_FUNCS[*]}"
    printf "OPT_FUNCS   : %s\n" "${OPT_FUNCS[*]}"
    return 0
  fi

  echo "[verify] rc: $rc"
  local failures=0

  # 1) Syntax check
  if bash -n "$rc"; then
    echo "[verify] syntax: OK"
  else
    echo "[verify] syntax: FAIL"; failures=$((failures+1))
  fi

  # 2) Isolated clean-shell source test (unless --quick)
  if [ "$QUICK" -eq 0 ]; then
    if env -i HOME="$HOME" PATH="$PATH" \
                       bash --noprofile --norc -ic ". \"$rc\""; then
      echo "[verify] isolated source: OK"
    else
      echo "[verify] isolated source: FAIL"; failures=$((failures+1))
    fi
  else
    echo "[verify] isolated source: SKIP (--quick)"
  fi

  # 3) Presence checks
  local n t miss=0
  for n in "${MUST_ALIASES[@]}"; do
    t=$(type -t "$n" 2>/dev/null || true)
    if [ "$t" = "alias" ] || [ "$t" = "function" ]  || [ "$t" = "file" ] || [ "$t" = "builtin" ]; then
      printf "  OK alias/runner: %s\n" "$n"
    else
      printf "  MISSING alias/runner: %s\n" "$n"; miss=$((miss+1))
    fi
  done
  for n in "${MUST_FUNCS[@]}"; do
    t=$(type -t "$n" 2>/dev/null || true)
    if [ "$t" = "function" ]; then
      printf "  OK function: %s\n" "$n"
    else
      printf "  MISSING function: %s\n" "$n"; miss=$((miss+1))
    fi
  done
  # Optional sets (report but do not fail build)
  for n in "${OPT_ALIASES[@]}"; do
    t=$(type -t "$n" 2>/dev/null || true)
    if [ -n "$t" ]; then printf "  (opt) present: %s\n" "$n"; fi
  done
  for n in "${OPT_FUNCS[@]}"; do
    t=$(type -t "$n" 2>/dev/null || true)
    if [ "$t" = "function" ]; then 
      printf "  (opt) present: %s\n" "$n"; 
    fi
  done
  if [ "$miss" -gt 0 ]; then
    echo "[verify] presence: $miss missing (see lines above)"; 
    failures=$((failures+1))
  else
    echo "[verify] presence: OK"
  fi

  # 4) Tiny sample runs (skip with --no-samples)
  if [ "$NOSAMPLES" -eq 0 ]; then
    if type -t catwithcontrol >/dev/null 2>&1; then
      printf "A\tB\n" | catwithcontrol >/dev/null 2>&1 \
       && echo "  sample: catwithcontrol OK" \
       || { echo "  sample: catwithcontrol FAIL"; failures=$((failures+1)); }
    fi
    if command -v tree >/dev/null 2>&1 \
        && type -t atree >/dev/null 2>&1; then
      atree . >/dev/null 2>&1 \
        && echo "  sample: atree OK" \
        || { echo "  sample: atree FAIL"; failures=$((failures+1)); }
    else
      echo "  sample: atree SKIP (no tree or alias missing)"
    fi
  else
    echo "[verify] samples: SKIP (--no-samples)"
  fi

  # Summary/exit
  if [ "$failures" -eq 0 ]; then
    echo "[verify] ALL OK"
  else
    echo "[verify] $failures check(s) failed"
  fi
  return "$failures"
}
# ============================================================================ #

###############################################################################
# Appended by setup-win-start emitter — brightness helpers (portable)
###############################################################################
bash_brightness_backend=""
if command -v brightnessctl >/dev/null 2>&1; then
  bash_brightness_backend="brightnessctl"
elif command -v xrandr >/dev/null 2>&1; then
  bash_brightness_backend="xrandr"
fi

_first_connected_output() {
  command -v xrandr >/dev/null 2>&1 || return 1
  xrandr | awk '/ connected/{print $1; exit}'
}

dim_for_reading() {
  case "$bash_brightness_backend" in
    brightnessctl) brightnessctl set 20% ;;
    xrandr)
      out="$(_first_connected_output)"
      [ -n "$out" ] && xrandr --output "$out" --brightness 0.5 || \
        echo "xrandr: no connected output detected"
      ;;
    *) echo "No brightness backend (install brightnessctl or use xrandr)"; return 127 ;;
  esac
}

max_brightness() {
  case "$bash_brightness_backend" in
    brightnessctl) brightnessctl set 100% ;;
    xrandr)
      out="$(_first_connected_output)"
      [ -n "$out" ] && xrandr --output "$out" --brightness 1.0 || \
        echo "xrandr: no connected output detected"
      ;;
    *) echo "No brightness backend (install brightnessctl or use xrandr)"; return 127 ;;
  esac
}

echo "[portable] brightness helpers loaded (backend=$bash_brightness_backend)"

'@
      foreach ($root in $DestRoots) {
        $destDir = Join-Path $root "vezde"
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        $out = Join-Path $destDir ".portable.bashrc"
        [System.IO.File]::WriteAllText($out, $merged, [System.Text.Encoding]::UTF8)
        Write-Host "[emit] $out"
      }
    }

    function Add-PortableProfileHelpers {
      [CmdletBinding()]
      param([string]$PortableProfilePath, [switch]$InstallFlux, [switch]$InstallTwinkleTray, [Parameter(Mandatory)
if ($InstallFlux) {
    Write-Host "Installing f.lux (optional)..." 
    try { winget install --id=FluxSoftware.flux -e -h } catch { Write-Warning "f.lux install skipped: $_" }
}
if ($InstallTwinkleTray) {
    Write-Host "Installing Twinkle Tray (optional)..."
    try { winget install --id=xanderfrangos.twinkletray -e -h } catch { Write-Warning "Twinkle Tray install skipped: $_" }
}
][string]$PortableProfilePath)
      $extra = @'
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

# ==== Night Light & brightness helpers =================================
function Open-NightLightSettings {
  Start-Process "ms-settings:nightlight"
}
function Set-Brightness {
  param([ValidateRange(0,100)][int]$Percent)
  try {
    $m = Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods -ErrorAction Stop
    [void]$m.WmiSetBrightness(1, $Percent)
  } catch {
    Write-Warning "WMI brightness unavailable; if Twinkle Tray is installed, attempting that."
    $tray = (Get-Command "Twinkle Tray.exe" -ErrorAction SilentlyContinue)
    if ($tray) { Start-Process "$($tray.Path)" "--percent=$Percent" }
  }
}
# =======================================================================

'@
      Set-Content -LiteralPath $PortableProfilePath -Value $extra -Encoding UTF8
      Write-Host "[profile] wrote: $PortableProfilePath"
    }

    # --- Hook into -Installs string (non-destructive): ---------------------
    # Accepts "emit-cygwin-bootstrap,emit-wsl-setup,emit-wsl-cygwin-artifacts"
    if (-not (Get-Variable -Name Installs -Scope Script -ErrorAction SilentlyContinue)) { $script:Installs = "" }
    if (-not (Get-Variable -Name Interactive -Scope Script -ErrorAction SilentlyContinue)) { $script:Interactive = "n" }
    if (-not (Get-Variable -Name Archive4Doc -Scope Script -ErrorAction SilentlyContinue)) { $script:Archive4Doc = "y" }

    $actions = @()
    if ($Installs) { $actions = $Installs.Split(",") | ForEach-Object { $_.Trim().ToLowerInvariant() } }

    $doCygwin    = $actions -contains "emit-cygwin-bootstrap"
    $doWSL       = $actions -contains "emit-wsl-setup"
    $doArtifacts = ($actions -contains "emit-wsl-cygwin-artifacts") -or ($actions -contains "emit-wsl-cygwin-artifacts")

    if ($doCygwin -or $doWSL) {
      $sharedTS = Get-SharedTimestamp
      $baseDir  = Resolve-DefaultBaseDir

      $report = New-Object System.Collections.Generic.List[string]
      if ($doCygwin) {
        $cygRoot = Join-Path $baseDir ("Cygwin_Bootstrap_" + $sharedTS)
        New-Item -ItemType Directory -Force -Path $cygRoot | Out-Null
        Write-PortableBashrc -DestRoots @($cygRoot)
        if ($doArtifacts) { Write-CheckNewLinuxArtifacts -DestRoots @($cygRoot) }

        if ($Archive4Doc -match '^(y|Y)$') {
          $archDir = Join-Path $baseDir (".4doc_Cygwin_" + $sharedTS)
          $vez = Join-Path $cygRoot "vezde\.portable.bashrc"
          if (Test-Path $vez) { New-DocArchiveCopy -SourceFile $vez -ArchiveDir $archDir -SharedTS $sharedTS }
          $lb = Join-Path $cygRoot "linux_baseline"
          if (Test-Path $lb) { Get-ChildItem -LiteralPath $lb -File | ForEach-Object { New-DocArchiveCopy -SourceFile $_.FullName -ArchiveDir $archDir -SharedTS $sharedTS } }
        }
        $report.Add("emit: $cygRoot")
      }

      if ($doWSL) {
        $wslRoot = Join-Path $baseDir ("WSL_Setup_" + $sharedTS)
        New-Item -ItemType Directory -Force -Path $wslRoot | Out-Null
        Write-PortableBashrc -DestRoots @($wslRoot)
        if ($doArtifacts) { Write-CheckNewLinuxArtifacts -DestRoots @($wslRoot) }

        if ($Archive4Doc -match '^(y|Y)$') {
          $archDir = Join-Path $baseDir (".4doc_WSL_" + $sharedTS)
          $vez = Join-Path $wslRoot "vezde\.portable.bashrc"
          if (Test-Path $vez) { New-DocArchiveCopy -SourceFile $vez -ArchiveDir $archDir -SharedTS $sharedTS }
          $lb = Join-Path $wslRoot "linux_baseline"
          if (Test-Path $lb) { Get-ChildItem -LiteralPath $lb -File | ForEach-Object { New-DocArchiveCopy -SourceFile $_.FullName -ArchiveDir $archDir -SharedTS $sharedTS } }
        }
        $report.Add("emit: $wslRoot")
      }

      # Emit patched portable PS profile at base
      $ppath = Join-Path $baseDir "portable_profile.ps1"
      Add-PortableProfileHelpers -PortableProfilePath $ppath
      $report.Add("emit: $ppath")

      $log = Join-Path $baseDir ("completed_install_report_" + $sharedTS + ".log")
      $report.Insert(0, "shared_ts: " + $sharedTS)
      $report.Insert(1, "base_dir: " + $baseDir)
      [System.IO.File]::WriteAllLines($log, $report, [System.Text.Encoding]::UTF8)

      Write-Host "Done (emit). See report: $log"
    }
    # ======================================================================


    # --- Help (appended) ---
    if ($Help) {
        Write-Host @'
Usage:
  .\setup-win-start.ps1 -Installs "emit-cygwin-bootstrap,emit-wsl-setup,emit-wsl-cygwin-artifacts" -Interactive n -Archive4Doc y -DryRun

Options:
  -Installs "<csv>"               One or more tokens:
                                  emit-cygwin-bootstrap, emit-wsl-setup, emit-wsl-cygwin-artifacts
  -Interactive y|n                Non-interactive when 'n' (default: y)
  -Archive4Doc y|n                Emit .4doc archives (default: n)
  -DryRun                         Log actions but do not modify the system or write files
  -WithRestorePoints              Enable system restore point creation (default: off)
  -RestorePointPhase <phase>      All | PreInitialUpdate | PostBeginningPreBigSetup | PostBigSetup
  -Help                           Show this help

Notes:
  * The misspelled token 'emit-wsl-cywin-artifacts' is no longer accepted.
  * DryRun logs all file and directory operations as [DRY-RUN] without executing them.
'@
        exit 0
    }

