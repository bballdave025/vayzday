#!/usr/bin/env python3

"""
dotfile_triage.py — quick scanner for Bash dotfiles to help curate a portable set.

USAGE:
  python dotfile_triage.py /path/to/vayzday   # or run in repo root without args

What it does:
- Recursively scans for common shell rc files (.bashrc, .bash_profile, .bash_aliases, *.bash)
- Extracts alias and function names
- Reports includes (source/. path lines)
- Flags portability markers:
  * Windows/Cygwin: cygpath, cygstart, /cygdrive/, powershell.exe, cmd.exe, notepad.exe, explorer.exe, winpty, clip.exe
  * macOS: pbcopy, pbpaste, open, -G with ls
  * Linux/X11: xclip, xsel, notify-send, xdg-open
  * WSL: wslpath, powershell.exe, /mnt/c
- Writes a JSON report next to the script and prints a human-readable summary.
"""
from __future__ import annotations
import sys, re, os, json
from pathlib import Path

ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()

GLOBS = [
    ".bashrc", ".bash_profile", ".bash_login", ".profile",
    ".bash_aliases", ".inputrc",
    "*.bash", "*.sh"
]

WIN_CYG_MARKERS = r"(cygpath|cygstart|/cygdrive/|powershell\.exe|cmd\.exe|notepad\.exe|explorer\.exe|winpty|clip\.exe)"
MAC_MARKERS     = r"(pbcopy|pbpaste|\bopen\b|ls\s+-G\b)"
LINUX_MARKERS   = r"(xclip|xsel|notify-send|xdg-open)"
WSL_MARKERS     = r"(wslpath|/mnt/c\b|powershell\.exe)"
SED_MARKERS     = r"\bsed\s+-i(\s|$)"
LS_COLOR        = r"\bls\s+(--color(?:=auto)?)\b"

INCLUDE_PAT     = re.compile(r"""^\s*(?:source|\.)\s+(['"]?)([^'"]+)\1""")
ALIAS_PAT       = re.compile(r"""^\s*alias\s+([A-Za-z0-9_]+)=['"]?""")
FUNC_PAT        = re.compile(r"""^\s*([A-Za-z0-9_]+)\s*\(\s*\)\s*\{""")
MARKER_PATS     = {
    "windows_cygwin": re.compile(WIN_CYG_MARKERS, re.I),
    "macos":          re.compile(MAC_MARKERS, re.I),
    "linux":          re.compile(LINUX_MARKERS, re.I),
    "wsl":            re.compile(WSL_MARKERS, re.I),
    "sed_inplace":    re.compile(SED_MARKERS),
    "ls_color":       re.compile(LS_COLOR),
}

def iter_files(root: Path):
    seen = set()
    for g in GLOBS:
        for p in root.rglob(g):
            if p.is_file() and p.suffix not in {".swp", ".swo"}:
                rp = p.resolve()
                if rp not in seen:
                    seen.add(rp)
                    yield rp

def scan_file(p: Path):
    aliases, funcs, includes, markers = [], [], [], []
    try:
        lines = p.read_text(encoding="utf-8", errors="ignore").splitlines()
    except Exception as e:
        return {"file": str(p), "error": str(e)}
    for i, line in enumerate(lines, 1):
        # Consider commented-out lines for markers (requested), but skip alias/func extraction if commented
        stripped = line.strip()
        is_comment = stripped.startswith("#")
        m = INCLUDE_PAT.match(line)
        if m and not is_comment:
            includes.append({"line": i, "target": m.group(2)})
        am = ALIAS_PAT.match(line)
        if am and not is_comment:
            aliases.append({"line": i, "name": am.group(1)})
        fm = FUNC_PAT.match(line)
        if fm and not is_comment:
            funcs.append({"line": i, "name": fm.group(1)})
        for tag, pat in MARKER_PATS.items():
            if pat.search(line):
                markers.append({"line": i, "tag": tag, "snippet": line.strip()[:200]})
    return {"file": str(p), "aliases": aliases, "functions": funcs, "includes": includes, "markers": markers}

def main():
    files = list(iter_files(ROOT))
    results = [scan_file(p) for p in files]
    out = {
        "root": str(ROOT),
        "files_scanned": [str(p) for p in files],
        "results": results,
        "summary": {
            "num_files": len(files),
            "num_aliases": sum(len(r.get("aliases", [])) for r in results),
            "num_functions": sum(len(r.get("functions", [])) for r in results),
            "num_includes": sum(len(r.get("includes", [])) for r in results),
            "num_markers": sum(len(r.get("markers", [])) for r in results),
        }
    }
    out_json = ROOT / ("dotfile_triage_report.json")
    try:
        out_json.write_text(json.dumps(out, indent=2), encoding="utf-8")
    except Exception:
        # Fallback to script directory
        out_json = Path(__file__).with_name("dotfile_triage_report.json")
        out_json.write_text(json.dumps(out, indent=2), encoding="utf-8")

    # Human-readable print
    print(f"[dotfile-triage] Scanned {out['summary']['num_files']} files under {ROOT}")
    print(f"  Aliases: {out['summary']['num_aliases']}  Functions: {out['summary']['num_functions']}  Includes: {out['summary']['num_includes']}  Flags: {out['summary']['num_markers']}")
    for r in results:
        if "error" in r: 
            print(f"  - {r['file']}: ERROR {r['error']}")
            continue
        flagged = r.get("markers", [])
        if flagged:
            print(f"  - {r['file']} — {len(flagged)} flags:")
            for f in flagged[:10]:
                print(f"      L{f['line']:>4} [{f['tag']}] {f['snippet']}")
            if len(flagged) > 10:
                print(f"      ... and {len(flagged)-10} more")
    print(f"\nJSON report: {out_json}")
    print("Tip: Open the JSON in an editor and pick functions/aliases to copy into ~/.portable.bashrc")
if __name__ == "__main__":
    main()
