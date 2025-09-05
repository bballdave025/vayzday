# ~/.portable.bashrc (portable core)
[ -f /etc/bash.bashrc ] && . /etc/bash.bashrc
# Quiet defaults that won't hurt
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias rmi='rm -i'
alias cpi='cp -i'
alias mvi='mv -i'
alias lessraw='less -r'
alias whence='type -a'                            # where, of a sort
alias grepcolor='grep --color=tty' ## DWB 2022-03-02  Standardize
alias cgrep='grep --color=auto'    ## DWB 2022-03-02  Standardize
alias grepc='grep --color=auto'
alias lsc='ls --color=auto'
alias lscolor='ls -hF --color=tty'
alias dir='ls --color=auto --format=vertical'
alias vdir='ls --color=auto --format=long'
alias ll='ls -l'                                  # long list
alias lh='ls -lah'
alias la='ls -A'                                  # all but . and ..
alias l='ls -CF'
alias ls_name_and_size='ls -Ss1pq --block-size=1'
alias runlog='runscriptreplayclean'
timestamp() { date +"%s_%Y-%m-%dT%H%M%S%z"; }
tripledate() { date && date +'%s' && timestamp; }
trpdate() { tripledate; }

##### PORTABLE ADDITIONS (requested) ###########################################

# Try to import your function bodies if available (repo or HOME copies)
for PF in "$HOME/my_repos_dwb/vayzday/.bballdave025_bash_functions" \
          "$HOME/.bballdave025_bash_functions"; do
  [ -f "$PF" ] && . "$PF" && break
done

# ---- Portable wrappers (no external deps) ----

# cat_with_control: show control chars (portable)
cat_with_control() { command -v cat >/dev/null || return 127; cat -ETv -- "$@"; }
alias catwithcontrol='cat_with_control'

# atree: ASCII tree (portable if `tree` exists)
atree() { if command -v tree >/dev/null; then tree --charset=ascii "$@"; else echo "tree not installed"; return 127; fi; }

# atreea: like atree, but shows hidden files and directories, needs `tree`
atreea() { if command -v tree >/dev/null; then tree --charset=ascii -a "$@"; else echo "tree not installed"; return 127; fi; } 


# checksituation: friendly timestamp trio (uses trpdate if present; else fallback)
checksituation() {
  if type trpdate >/dev/null 2>&1; then trpdate
  else
    date; date +'%s'; date +'%s_%Y-%m-%dT%H%M%S%z'
  fi
}

# Timestamp helpers
dbldate()      { date && date +'%s'; }
tripledate()   { date && date +'%s' && date +'%s_%Y-%m-%dT%H%M%S%z'; }
ttdate()       { date +'%s_%Y-%m-%dT%H%M%S%z'; }

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
  # TODO: decide policy for `alias grep='grep --color=auto'` vs unalias.
  :
}
alias set_aliases_mt='set_main_terminal_aliases'
alias seta_mt='set_main_terminal_aliases'
alias samt='set_main_terminal_aliases'

# ---- Alias the function-runners when the functions exist ----
type git_branch_func       >/dev/null 2>&1 && alias git_branch='git_branch_func'
type git_trace_cmd_func    >/dev/null 2>&1 && alias gittracecmd='git_trace_cmd_func'
type git_trace_cmd_func    >/dev/null 2>&1 && alias gittracecommand='git_trace_cmd_func'
type get2byteandunicode4char>/dev/null 2>&1 && alias get2bu4char='get2byteandunicode4char'
type get2byteandunicode4char>/dev/null 2>&1 && alias get24char='get2byteandunicode4char'
type definewithheredoc     >/dev/null 2>&1 && alias dhd='definewithheredoc'
type help_definewithheredoc>/dev/null 2>&1 && alias help_dhd='help_definewithheredoc'

# cd_func is requested even though it overrides the builtin `cd`
type cd_func >/dev/null 2>&1 && alias cd='cd_func'

# Provide $HELPDOC default text if unset (used by help_definewithheredoc)
: "${HELPDOC:=Portable help: definewithheredoc usage text not set.}"

# ---- Ubuntu test placeholders (requested) ----
# ## Place for set_title function
# : '(use the logic of sed s|function|alias| on the runner when justified)'

# ## Place for revert_title_path function
# : '(use the logic of sed s|function|alias| on the runner when justified)'

# ## Place for exts_in_dir function
# : '(consider replacing long alias with a function; TINN)'

# ---- Explicitly excluded for now ----
# htbetween_func   # (per request)
# xterm_double_wide xterm_std xterm_std_width_dbl_height  # (per request)

###############################################################################

: "${strcleantermlog:=Portable terminal log cleanup placeholder.}"
alias forcleaningterminallog='echo "$strcleantermlog"'


definewithheredoc ()
{
    IFS='
' read -r -d '' ${1} || true
}


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
gcolor(){ case "$1" in on)alias grep='grep --color=auto';; off)unalias grep 2>/dev/null;; status|'')type -a grep;; *)echo "usage: gcolor {on|off|status}";return 2;; esac; }

# --- egrep/fgrep helpers (keep commands plain) ---
unalias egrep 2>/dev/null || true
unalias fgrep 2>/dev/null || true
alias eg='grep -E'; alias fg='grep -F'
alias egcolor='grep -E --color=auto'; alias fgcolor='grep -F --color=auto'

# --- diff helpers ---
diffcolor(){ if diff --help 2>&1 | grep -q ' --color'; then command diff --color=auto "$@"; else command diff "$@"; fi; }
alias bdiff='LC_ALL=C diff'

# --- iproute2 color helper ---
ipcolor(){ command -v ip >/dev/null || { echo "ip not found" >&2; return 127; }; command ip -c "$@"; }


# --- runscriptreplayclean: interactive OR one-shot command logging -----------
# Usage:
#   runscriptreplayclean                    # full interactive session; exit to finish
#   runscriptreplayclean -l my.log         # interactive; append to my.log
#   runscriptreplayclean -- <cmd args...>  # one-shot command with BEGIN/END markers
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
    for arg in "$@"; do q+=" $(printf '%q' "$arg")"; done
    cmd_str="${q# }"

    # Run the command under a child bash, stamping BEGIN/END
    script -afe "$logfile" bash -lc \
'printf "[runlog] BEGIN %(%F %T %z)T\n" -1
trap '\''rc=$?; printf "[runlog] END rc=%s %(%F %T %z)T\n" "$rc" -1'\'' EXIT
'"$cmd_str"
    rc=$?
  fi

  # Make a cleaned copy (ANSI escapes stripped) alongside the raw log
  # If you prefer screen-hardcopy cleaning, uncomment the screen block below.
  local clean="${logfile%.log}_clean.log"
  sed -r $'s/\x1B\\[[0-9;]*[[:alpha:]]//g' "$logfile" > "$clean" 2>/dev/null || cp -f "$logfile" "$clean"

  # -- screen-based cleaner (optional; may vary across distros) --
  # if command -v screen >/dev/null 2>&1; then
  #   screen -D -m -c /dev/null sh -c \
  #     "screen -X scrollback 500000; cat < \"$logfile\"; screen -X hardcopy -h \"$clean\"" \
  #   || sed -r $'s/\x1B\\[[0-9;]*[[:alpha:]]//g' "$logfile" > "$clean"
  # fi

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
      *) echo "usage: verify_portable_bashrc [-f FILE] [--quick] [--no-samples] [--print]"; return 2 ;;
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
    if env -i HOME="$HOME" PATH="$PATH" bash --noprofile --norc -ic ". \"$rc\""; then
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
    if [ "$t" = "alias" ] || [ "$t" = "function" ] || [ "$t" = "file" ] || [ "$t" = "builtin" ]; then
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
    if [ "$t" = "function" ]; then printf "  (opt) present: %s\n" "$n"; fi
  done
  if [ "$miss" -gt 0 ]; then
    echo "[verify] presence: $miss missing (see lines above)"; failures=$((failures+1))
  else
    echo "[verify] presence: OK"
  fi

  # 4) Tiny sample runs (skip with --no-samples)
  if [ "$NOSAMPLES" -eq 0 ]; then
    if type -t catwithcontrol >/dev/null 2>&1; then
      printf "A\tB\n" | catwithcontrol >/dev/null 2>&1 && echo "  sample: catwithcontrol OK" || { echo "  sample: catwithcontrol FAIL"; failures=$((failures+1)); }
    fi
    if command -v tree >/dev/null 2>&1 && type -t atree >/dev/null 2>&1; then
      atree . >/dev/null 2>&1 && echo "  sample: atree OK" || { echo "  sample: atree FAIL"; failures=$((failures+1)); }
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
