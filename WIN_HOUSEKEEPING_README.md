# WIN_HOUSEKEEPING_README

> Quick-start housekeeping for a fresh Windows dev box. This pairs with:
> - `setup-win-start.ps1` — bootstrap installer, WSL on D:\, restore-point maker
> - `system_audit.ps1`     — no-installs, thorough machine report

---

## 1) Before You Begin
1. **Create a restore point (GUI)** — Win+R → `SystemPropertiesProtection` → Turn on protection (C:) → Set Max Usage ≈ **5%** → **Create** (“Pre-setup …”).
2. Run **Windows Update** and reboot.
3. Open **Windows PowerShell (Admin)** for the scripts below.

## 2) Run the System Audit (optional but recommended)
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
.\system_audit.ps1
```
This writes `win_system_audit_<ts>.txt` to your Desktop.

## 3) Bootstrap Install (WSL on D:\, tools, restore points)
Example (non-interactive, my suggested baseline):
```powershell
.\setup-win-start.ps1 -Installs "gpg,7zip,wsl-fedora,git,docker-wsl,firefox,notepad++,vlc,imagemagick-win,cygwin" -Interactive n
```
**What it does**
- Ensures **System Protection** is on → creates **Pre-Setup** restore point.
- Sets **WSL default dir** to `D:\WSL` and installs Fedora/Ubuntu (tokens).
- Detects Ubuntu/Fedora distros and **relocates** them to `D:\WSL` (auto in non-interactive; prompts otherwise).
- Installs requested tools via **winget** (hash-verified); Explorer set to show **extensions** and **hidden/system files**.
- Writes report to Desktop (`partial_…` or `completed_…`).
- Creates **Post-Setup** restore point on success.

## 4) Tokens for `-Installs`
- **Core**: `gpg`, `7zip`, `git`, `git-win`, `git-wsl`
- **WSL**: `wsl-fedora`, `wsl-ubuntu`, `set-default-wsl1`
- **Docker**: `docker-wsl`, `docker-desktop-win`
- **Browsers**: `firefox`, `chrome`
- **Editors/Tools**: `notepad++`, `imagemagick-win`, `imagemagick-wsl`, `winscp`, `putty`, `pageant`, `vim`
- **Media**: `vlc`, `k-lite-codecs`
- **Office**: `libreoffice`, `openoffice`
- **Dev**: `vc-redist`, `jdk`, `python-non-conda`, `conda` (prefer Miniforge inside WSL)
- **Extra**: `chocolatey` (licensing note), `cygwin` (download-only)

## 5) Notes on Verification
- `winget` validates manifests/hashes; `dnf` uses repo GPG by default.
- For **manual** downloads (e.g., Cygwin), the script can SHA256-check (and GPG-verify if provided) when `-VerifyManualDownloads y`.

## 6) Common Post-Install Steps
- Launch **Docker Desktop** once → **Settings → Resources → WSL integration** → enable for your distro(s).
- In WSL Fedora: install CLI tools (`sudo dnf -y update && sudo dnf -y install git vim imagemagick`).  
- Set up **SSH keys** and **Git signing** (GPG) as needed.

## 7) Restore / Rollback
- Run `rstrui.exe` (System Restore) to return to **Pre-Setup** if needed.
- Disk usage: Restore Points are **not full images**; they are pruned at the configured cap (5% suggested).

## 8) Troubleshooting
- **winget missing**: Install **App Installer** from Microsoft Store, then re-run.
- **WSL errors**: Enable virtualization in BIOS/UEFI; reboot; re-run script.
- **Low disk**: Relocate WSL to D:\ (script does this); keep Docker images on D:\ as well.
- **Chrome freezes**: See `chrome_freeze_guide.pdf` for a two-page action & prevention guide.

---

**License**: MIT (adjust as desired).  
**Author**: Dave Black + ChatGPT assistant.
