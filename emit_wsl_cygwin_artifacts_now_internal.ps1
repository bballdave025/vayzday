    <#
      emit_wsl_cygwin_artifacts.ps1
      Drop‑in helper for setup‑win‑start.ps1

      Exposes:
        - New‑SafeRestorePoint
        - Write‑PortableBashrc
        - Write‑CheckNewLinuxArtifacts
        - Install‑OptionalDisplayTools (f.lux, Twinkle Tray)
        - Add‑PortableProfileHelpers (adds Open‑NightLightSettings & Set‑Brightness)

      Usage from setup‑win‑start.ps1:
        . "$PSScriptRoot\emit_wsl_cygwin_artifacts.ps1"
        New-SafeRestorePoint "Pre Initial Update"
        # ... reboot / updates ...
        New-SafeRestorePoint "Post Beginning, Pre Big Setup"
        $destRoots = @("$env:USERPROFILE\Desktop\WSL_Setup", "$env:USERPROFILE\Desktop\Cygwin_Bootstrap")
        Write-PortableBashrc -DestRoots $destRoots -SourceBashrcPath "$PSScriptRoot\portable_bashrc.txt"
        Write-CheckNewLinuxArtifacts -DestRoots $destRoots
        Add‑PortableProfileHelpers -PortableProfilePath "$PSScriptRoot\portable_profile.ps1" -InstallFlux:$InstallFlux -InstallTwinkleTray:$InstallTwinkleTray
        New-SafeRestorePoint "Post Big Setup"
    #>

    [CmdletBinding()]
    param()

    function New-SafeRestorePoint {
      [CmdletBinding()]
      param(
        [Parameter(Mandatory)][string]$Description
      )
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

    function _Read-FileTextUtf8 {
      param([string]$Path)
      if (Test-Path -LiteralPath $Path) {
        return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
      }
      return $null
    }

    function Write-PortableBashrc {
      [CmdletBinding()]
      param(
        [Parameter(Mandatory)][string[]]$DestRoots,
        [Parameter(Mandatory)][string]$SourceBashrcPath
      )
      $src = _Read-FileTextUtf8 -Path $SourceBashrcPath
      if (-not $src) { throw "Source bashrc file not found: $SourceBashrcPath" }

      $appendix = @"
###############################################################################
# Appended by setup-win-start emitter — brightness helpers (portable)
# See Windows side for PowerShell Night Light helpers
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
"@

      $merged = ($src.TrimEnd() + "`n`n" + $appendix + "`n")
      foreach ($root in $DestRoots) {
        $destDir = Join-Path $root "vezde"
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        $out = Join-Path $destDir ".portable.bashrc"
        [System.IO.File]::WriteAllText($out, $merged, [System.Text.Encoding]::UTF8)
        Write-Host "[emit] $out"
      }
    }

    function Write-CheckNewLinuxArtifacts {
      [CmdletBinding()]
      param([Parameter(Mandatory)][string[]]$DestRoots)

      $scriptText = @"
#!/usr/bin/env bash
set -euo pipefail
TS="\$(date +'%s_%Y-%m-%dT%H%M%S%z')"
BACK="\$HOME/.important_backups"
OUT="\${BACK}/new_linux_bash_\${TS}.out"
mkdir -p "\$BACK"
{
  echo "==== new_linux_bash snapshot @ \$(date) ===="
  echo "user: \$USER  host: \$(hostname)"
  echo
  echo "== shell =="
  echo "BASH_VERSION=\$BASH_VERSION"
  echo "SHELL=\$SHELL"
  echo "TTY=\$(tty || true)"
  echo
  echo "== key env =="
  printf "IFS=("; printf %q "\$IFS"; printf ")\n"
  echo "PATH=\$PATH"
  echo "MANPATH=\${MANPATH-}"
  echo "PS1=\${PS1-}"
  echo "PROMPT_COMMAND=\${PROMPT_COMMAND-}"
  echo "TITLE_STRING=\${TITLE_STRING-}"
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
    printf "%-14s" "\$b"; command -v "\$b" || echo "not found"
  done
  echo
  echo "== dotfiles (backups) =="
} | tee "\$OUT"
for f in .bashrc .profile .vimrc .gitconfig .bash_profile .inputrc; do
  [ -f "\$HOME/\$f" ] && cp -a "\$HOME/\$f" "\$BACK/\${f}.\${TS}.bak" || true
done
syslist=(/etc/profile /etc/bashrc /etc/bash.bashrc /etc/environment /etc/manpath.config)
for s in "\${syslist[@]}"; do
  [ -r "\$s" ] && cp -a "\$s" "\$BACK/\$(basename "\$s").\${TS}.bak" || true
done
printf %s "\$IFS" > "\$BACK/IFS.\${TS}.bak"
: "\${PATH}"    ; printf %s "\$PATH"  > "\$BACK/PATH.\${TS}.bak"
: "\${MANPATH-}"; printf %s "\${MANPATH-}" > "\$BACK/MANPATH.\${TS}.bak"
: "\${PS1-}"    ; printf %s "\${PS1-}" > "\$BACK/PS1.\${TS}.bak"
: "\${PROMPT_COMMAND-}" ; printf %s "\${PROMPT_COMMAND-}" > "\$BACK/PROMPT_COMMAND.\${TS}.bak"
: "\${TITLE_STRING-}"   ; printf %s "\${TITLE_STRING-}"   > "\$BACK/TITLE_STRING.\${TS}.bak"
echo "Snapshot written to: \$OUT"
echo "Backups directory:   \$BACK"
"@

      $readmeText = @"
check_new_linux_bash — quick baseline capture (WSL, Fedora, Ubuntu, Cygwin)

What it does
• Saves a timestamped environment snapshot to ~/.important_backups/new_linux_bash_<epoch>_<ISO>.out
• Backs up common dotfiles (.bashrc, .profile, .vimrc, .gitconfig, etc.) with the same timestamp.
• Backs up pre‑dotfile system files when readable (/etc/profile, /etc/bashrc or /etc/bash.bashrc, /etc/environment, /etc/manpath.config).
• Saves single‑value captures (IFS, PATH, MANPATH, PS1, PROMPT_COMMAND, TITLE_STRING) into separate .bak files.

How to run
  1) Place both files in any shell environment (WSL, Fedora, Ubuntu, or Cygwin):
     - check_new_linux_bash.sh
     - .portable.bashrc   (optional, but nice!)
  2) Make the script executable and run it:
       chmod +x check_new_linux_bash.sh
       ./check_new_linux_bash.sh
  3) Review outputs in ~/.important_backups/

Tips
• If you plan to adopt .portable.bashrc, you can source it first:
     . "$HOME/vezde/.portable.bashrc"  # or wherever you placed it
• If `tree` is installed, try `atree` for ASCII directory views.
• For a clean session log, try:  runlog -- bash -lc 'echo hello'
"@

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

    function Add-PortableProfileHelpers {
      [CmdletBinding()]
      param(
        [Parameter(Mandatory)][string]$PortableProfilePath,
        [switch]$InstallFlux,
        [switch]$InstallTwinkleTray
      )
      $extra = @"

# ==== Night Light & brightness helpers =================================
function Open-NightLightSettings {
  Start-Process "ms-settings:nightlight"
}

function Set-Brightness {
  param([ValidateRange(0,100)][int]`$Percent)
  try {
    # WMI path works on many laptops; may not on external monitors
    `$m = Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods -ErrorAction Stop
    [void]`$m.WmiSetBrightness(1, `$Percent)
  } catch {
    Write-Warning "WMI brightness unavailable; if Twinkle Tray is installed, attempting that."
    `$tray = (Get-Command "Twinkle Tray.exe" -ErrorAction SilentlyContinue)
    if (`$tray) { Start-Process "`$($tray.Path)" "--percent=`$Percent" }
  }
}
# =======================================================================

"@

      if (Test-Path -LiteralPath $PortableProfilePath) {
        Add-Content -LiteralPath $PortableProfilePath -Value $extra
        Write-Host "[profile] Patched: $PortableProfilePath"
      } else {
        Set-Content -LiteralPath $PortableProfilePath -Value $extra -Encoding UTF8
        Write-Host "[profile] Created: $PortableProfilePath"
      }

      if ($InstallFlux) {
        try { winget install --id=flux.flux --source=winget -e }
        catch { Write-Warning "winget f.lux install failed: $_" }
      }
      if ($InstallTwinkleTray) {
        try { winget install --id=twinkletray.twinkletray --source=winget -e }
        catch { Write-Warning "winget Twinkle Tray install failed: $_" }
      }
    }