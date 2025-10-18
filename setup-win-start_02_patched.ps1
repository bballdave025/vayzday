# setup-win-start_patched.ps1 — example wiring
param(
  [switch]$InstallFlux,
  [switch]$InstallTwinkleTray
)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$here\emit_wsl_cygwin_artifacts.ps1"

# 1) Pre-initial update restore point
New-SafeRestorePoint "Pre Initial Update"

# (User: restart & run Windows Updates manually here if desired)

# 2) Post-beginning, pre-big-setup restore point
New-SafeRestorePoint "Post Beginning, Pre Big Setup"

# 3) Emit artifacts for WSL + Cygwin
$roots = @("$env:USERPROFILE\Desktop\WSL_Setup", "$env:USERPROFILE\Desktop\Cygwin_Bootstrap")
Write-PortableBashrc -DestRoots $roots -SourceBashrcPath (Join-Path $here "portable_bashrc.txt")
Write-CheckNewLinuxArtifacts -DestRoots $roots

# 4) Patch portable PowerShell profile (add helpers; optionally install tools)
Add-PortableProfileHelpers -PortableProfilePath (Join-Path $here "portable_profile.ps1") -InstallFlux:$InstallFlux -InstallTwinkleTray:$InstallTwinkleTray

# 5) Post big setup restore point
New-SafeRestorePoint "Post Big Setup"

Write-Host "All done. Artifacts under:"
$roots | ForEach-Object { Write-Host " - $_" }