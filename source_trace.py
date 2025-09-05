#!/usr/bin/env python3

"""
source_trace.py — Trace transitive 'source' / '.' includes starting from one or more shell rc files.

USAGE:
  python source_trace.py                      # starts from ~/.bashrc
  python source_trace.py ~/.bashrc ~/.bash_aliases ~/.bash_functions

What it does:
- Recursively finds files included via `source FILE` or `. FILE` (handles quotes, ~, $VARS, and relative paths).
- Expands simple globs in include paths (e.g., $HOME/.bashrc.d/*.bash).
- Emits a sorted list of all discovered files (existing and missing) and a JSON report with basic flags.
- Flags common portability markers (Cygwin/Windows/macOS/Linux/WSL tokens) for quick eyeballing.

Limitations:
- Doesn't evaluate conditionals or complex command substitutions; it's a static pass.
- Only picks up straightforward includes on a single line.
"""
from __future__ import annotations
import os, re, sys, json, glob
from pathlib import Path
from typing import Dict, List, Set

INCLUDE_RE = re.compile(r"""^\s*(?:source|\.)\s+(?P<q>['"]?)(?P<path>[^#\n;]+?)(?P=q)(?:\s|;|$)""")

MARKERS = {
    "windows_cygwin": re.compile(r"(cygpath|cygstart|/cygdrive/|powershell\.exe|cmd\.exe|notepad\.exe|explorer\.exe|winpty|clip\.exe)", re.I),
    "macos": re.compile(r"(pbcopy|pbpaste|\bopen\b|ls\s+-G\b)", re.I),
    "linux": re.compile(r"(xclip|xsel|notify-send|xdg-open)", re.I),
    "wsl": re.compile(r"(wslpath|/mnt/c\b|powershell\.exe)", re.I),
    "sed_inplace": re.compile(r"\bsed\s+-i(\s|$)"),
    "ls_color": re.compile(r"\bls\s+(--color(?:=auto)?)\b"),
}

def resolve_path(raw: str, base_dir: Path) -> List[Path]:
    raw = raw.strip()
    # Expand env vars and ~
    expanded = os.path.expanduser(os.path.expandvars(raw))
    # If relative, join to including file's dir
    if not os.path.isabs(expanded):
        expanded = str((base_dir / expanded).resolve())
    # Expand globs (if any); if none matched, return the literal path
    matches = [Path(p) for p in glob.glob(expanded)]
    return matches or [Path(expanded)]

def scan_file(p: Path, visited: Set[Path], graph: Dict[str, dict]):
    try:
        text = p.read_text(encoding="utf-8", errors="ignore")
    except Exception as e:
        graph[str(p)] = {"exists": p.exists(), "error": str(e), "includes": [], "markers": []}
        return
    includes = []
    markers = []
    for lineno, line in enumerate(text.splitlines(), 1):
        # collect markers even in comments (for context)
        for tag, pat in MARKERS.items():
            if pat.search(line):
                markers.append({"line": lineno, "tag": tag, "snippet": line.strip()[:200]})
        m = INCLUDE_RE.match(line)
        if not m:
            continue
        inc_raw = m.group("path").strip()
        # skip includes that look like commands/pipelines
        if inc_raw.startswith("(") or inc_raw.startswith("$("):
            continue
        for inc in resolve_path(inc_raw, p.parent):
            includes.append({"line": lineno, "raw": inc_raw, "path": str(inc), "exists": inc.exists()})
    graph[str(p)] = {"exists": p.exists(), "includes": includes, "markers": markers}
    for inc in includes:
        ipath = Path(inc["path"])
        if ipath.exists() and ipath.is_file() and ipath not in visited:
            visited.add(ipath)
            scan_file(ipath, visited, graph)

def main():
    start_files = sys.argv[1:] or [os.path.expanduser("~/.bashrc")]
    roots = [Path(os.path.expanduser(os.path.expandvars(s))).resolve() for s in start_files]
    visited: Set[Path] = set()
    graph: Dict[str, dict] = {}
    for r in roots:
        visited.add(r)
        scan_file(r, visited, graph)
    all_paths = sorted(graph.keys())
    existing = sorted([p for p in all_paths if graph[p].get("exists")])
    missing  = sorted([p for p in all_paths if not graph[p].get("exists")])
    # Flatten includes set for convenience
    includes_set = set()
    for info in graph.values():
        for inc in info.get("includes", []):
            includes_set.add(inc["path"])
    includes = sorted(includes_set)

    report = {
        "start_files": [str(r) for r in roots],
        "all_files": all_paths,
        "existing": existing,
        "missing": missing,
        "graph": graph,
    }
    out_json = Path.cwd() / "source_trace_report.json"
    try:
        out_json.write_text(json.dumps(report, indent=2), encoding="utf-8")
    except Exception:
        out_json = Path(os.path.expanduser("~")) / "source_trace_report.json"
        out_json.write_text(json.dumps(report, indent=2), encoding="utf-8")

    print("[source-trace] Start files:")
    for r in roots:
        print("  -", r)
    print(f"[source-trace] Total discovered: {len(all_paths)}  (existing: {len(existing)}, missing: {len(missing)})")
    if missing:
        print("  Missing includes:")
        for m in missing[:20]:
            print("   -", m)
        if len(missing) > 20:
            print(f"    ... and {len(missing)-20} more")
    print("\n[source-trace] JSON report:", out_json)
    print("Open it in your editor to see per-file markers and include lines.")

if __name__ == "__main__":
    main()
