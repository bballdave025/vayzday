Cygwin Headless Bootstrap - README (Plain Text Edition)

This README explains the two bootstrap scripts for a non-GUI Cygwin install with signature verification and Android ADB tools.

------------------------------------------------------------
OVERVIEW
------------------------------------------------------------
bootstrap.cmd  - Windows-side installer. Prefers winget; if not available, it downloads and verifies Cygwin's installer, installs headlessly, and sets up the Mintty terminal shortcut and cyg-bootstrap.sh.

cyg-bootstrap.sh - Runs inside Cygwin. Adds PATH entries, installs helpful packages, and creates the split_bottom.sh script for Android split-screen control.

------------------------------------------------------------
QUICK START
------------------------------------------------------------
1. Save bootstrap.cmd anywhere.
2. Run it as Administrator.
3. Wait for completion. It will create a Cygwin Terminal shortcut on the desktop.
4. Open Cygwin Terminal and test:
   adb devices
   splitbot com.android.chrome/com.google.android.apps.chrome.Main

------------------------------------------------------------
VERIFICATION WORKFLOW
------------------------------------------------------------
When winget is unavailable, bootstrap.cmd verifies the installer using GPG.
1. Downloads setup-x86_64.exe and setup-x86_64.exe.sig.
2. Scrapes the fingerprint from cygwin.com/install.html.
3. Imports the key for cygwin@cygwin.com using gpg --locate-keys.
4. Compares the scraped fingerprint and the one from GPG.
5. If they match, verifies the signature using gpg --verify.
6. Installs only after verification succeeds.

------------------------------------------------------------
MANUAL VERIFICATION IF SCRAPER FAILS
------------------------------------------------------------
1. Visit https://www.cygwin.com/install.html.
2. Copy the Primary key fingerprint.
3. Run:
   gpg --locate-keys cygwin@cygwin.com
   gpg --fingerprint cygwin@cygwin.com
4. Check the fingerprint matches the website.
5. Run gpg --verify setup-x86_64.exe.sig setup-x86_64.exe.
6. If correct, re-run bootstrap.cmd or skip to :SETUPRUN section.

------------------------------------------------------------
COMMON PITFALLS
------------------------------------------------------------
Rebase or dash hang: Close all Cygwin or Git Bash windows, then re-run bootstrap.cmd. If still stuck:
   /usr/bin/rebase-trigger full
   exit
and re-run setup.

ADB unauthorized: Check your phone for the Allow USB debugging prompt.

No GPG detected: Install Git for Windows or Gpg4win before running, or rely on winget.

------------------------------------------------------------
WHY MIRRORS.KERNEL.ORG
------------------------------------------------------------
This mirror is stable and globally reliable, avoiding prompt-driven mirror selection.

------------------------------------------------------------
ADB SPLIT-BOTTOM HELPER
------------------------------------------------------------
The split_bottom.sh script launches a stub app (Keep, Settings, or Calculator) on the top half of Android split-screen and your chosen app in the bottom half. It auto-detects screen size and swaps positions if needed.

Usage:
   splitbot com.android.chrome/com.google.android.apps.chrome.Main
   splitbot com.android.settings/.Settings

------------------------------------------------------------
INTEGRITY CHECKS
------------------------------------------------------------
SHA-256 for Cygwin_Headless_Bootstrap_Full.zip:
34294314692b544e3bf4d90649919560c3af6c7adfad40e243678541a3ae7576

To verify:
   sha256sum Cygwin_Headless_Bootstrap_Full.zip

------------------------------------------------------------
LICENSE
------------------------------------------------------------
MIT License. Based on public Cygwin documentation and GPG verification examples.

Maintained scripts and notes compiled for Dave BLACK, 2025.
