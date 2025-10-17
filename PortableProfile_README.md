# Portable PowerShell Profile

This profile is meant to be portable: save it anywhere and dot-source it from your default profile.

## Install

1. Save the profile somewhere persistent, e.g.:
```powershell
$dest = "$HOME\portable_profile.ps1"
# (Replace URL below with your own repo location if applicable)
# Invoke-WebRequest -UseBasicParsing -Uri https://example.com/portable_profile.ps1 -OutFile $dest
```
2. Ensure your default profile exists:
```powershell
if (!(Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
```
3. Add a dot-source line to your profile:
```powershell
Add-Content $PROFILE "`n. `$HOME\portable_profile.ps1"
```
4. Reload:
```powershell
. $PROFILE
```

## What you get
- `timestamp`, `ttdate`, `iso-only-timestamp-short`, `iso-only-timestamp-long`
- `ts_iso_compact`, `ts_iso_short`, `ts_iso_webby`, `ts_iso_long`
- `Use-SessionPolicy`, `Use-StrictPolicy`, `Use-UserRemoteSigned`
- `sudo`, `sudo-pwsh`
- `Set-Brightness 30`, `Dim-ForReading`, `Max-Brightness`
- Aliases: `ll`, `grep`, `which`

## Notes
- Brightness control uses WMI and may not work on external displays.
- Changing LocalMachine policy requires Admin. For most dev work, use `Use-SessionPolicy` or `Use-UserRemoteSigned`.
