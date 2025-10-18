#!/usr/bin/env bash
set -euo pipefail

TS="$(date +'%s_%Y-%m-%dT%H%M%S%z')"
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
  printf "IFS=("; printf %q "$IFS"; printf ")\n"
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

# system pre-dotfiles when readable
syslist=(/etc/profile /etc/bashrc /etc/bash.bashrc /etc/environment /etc/manpath.config)
for s in "${syslist[@]}"; do
  [ -r "$s" ] && cp -a "$s" "$BACK/$(basename "$s").${TS}.bak" || true
done

# separate single-value captures
printf %s "$IFS" > "$BACK/IFS.${TS}.bak"
: "${PATH}"    ; printf %s "$PATH"  > "$BACK/PATH.${TS}.bak"
: "${MANPATH-}"; printf %s "${MANPATH-}" > "$BACK/MANPATH.${TS}.bak"
: "${PS1-}"    ; printf %s "${PS1-}" > "$BACK/PS1.${TS}.bak"
: "${PROMPT_COMMAND-}" ; printf %s "${PROMPT_COMMAND-}" > "$BACK/PROMPT_COMMAND.${TS}.bak"
: "${TITLE_STRING-}"   ; printf %s "${TITLE_STRING-}"   > "$BACK/TITLE_STRING.${TS}.bak"

echo "Snapshot written to: $OUT"
echo "Backups directory:   $BACK"