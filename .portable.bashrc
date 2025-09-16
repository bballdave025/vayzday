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
DEFAULT_DWB_RHEL_PROMPT_COMMAND=\
'echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007"'
DEFAULT_DWB_UBUNTU_PROMPT_COMMAND=\
'echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007""'
DEFAULT_DWB_CYGWIN_PROMPT_COMMAND=\
'echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007"'

DEFAULT_PROMPT_COMMAND="${ORIG_PROMPT_COMMAND}"

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
NOW_ORIG_CYGWIN_PS1=" <=> conda environment, blank means none activated\n\[\e[38;5;48m\]\$(git_branch)\[\e[0m\] <=> git branch, blank means not in a git repo\[\e]0;\w\a\]\n\[\e[32m\]bballdave025@MY-MACHINE \[\e[33m\]\w\[\e[0m\]\n\$ "
NOW_ORIG_UBUNTU_PS1=" <=> conda environment, blank means none activated\n\[\e[38;5;48m\]\$(git_branch)\[\e[0m\] <=> git branch, blank means not in a git repo\[\e]0;\w\a\]\n\[\e[32m\]bballdave025@MY-MACHINE \[\e[33m\]\w\[\e[0m\]\n\$ "
NOW_ORIG_RHEL_PS1=" <=> conda environment, blank means none activated\n\[\e[38;5;48m\]\$(git_branch)\[\e[0m\] <=> git branch, blank means not in a git repo\[\e]0;\w\a\]\n\[\e[32m\]bballdave025@MY-MACHINE \[\e[33m\]\w\[\e[0m\]\n\$ "

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
gethex4char()
{
  if [ "$@" = "-h" -o "$@" = "--help" ]; then
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
  elif [ "$@" = "'" ]; then
    echo "0x22"
  elif [ "$@" = "\"" ]; then
    echo "0x28"
  elif [ "$@" = "\\" ]; then
    echo "0x5c"
  elif [ "$@" = "%" ]; then
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
  if [ "$@" = "-h" -o "$@" = "--help" ]; then
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
  elif [ "$@" = "'" ]; then
    hex_str="22"
  elif [ "$@" = "\"" ]; then
    hex_str="28"
  elif [ "$@" = "\\" ]; then
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
  if [ "$@" = "-h" -o "$@" = "--help" ] 2>/dev/null; then
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
  elif [ "$@" = "'" ]; then
    echo "U+0022"
  elif [ "$@" = "\"" ]; then
    echo "U+0028"
  elif [ "$@" = "\\" ]; then
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
  if [ "$@" = "-h" -o "$@" = "--help" ]; then
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
    codepoint_str="$@"
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
  if [ "$@" = "-h" -o "$@" = "--help" ]; then
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

diffwithcontrol()
{
  dhd dwc_help_str <<'EndOfDWC' | sed 's#^[.]$##g'
.
HELP FOR:
 diffwithcontrol

@AUTHOR
 David Wallace BLACK
 contact via electronic mail
 user: dblack          server: captioncall   tld: com
 user: thedavidwblack  server: google        tld: com

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
  cat -ETv -- "$@"; 
}
alias catwithcontrol='cat_with_control'

# atree: ASCII tree (portable if `tree` exists)
atree() 
{ if command -v tree >/dev/null; then 
    tree --charset=ascii "$@"; 
  else 
    echo "tree not installed"; 
    return 127; 
  fi; }

# atreea: like atree, but shows hidden files and directories, needs `tree`
atreea() 
{
  if command -v tree >/dev/null; then 
    tree --charset=ascii -a "$@"; 
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
  # TODO: decide policy for `alias grep='grep --color=auto'` vs unalias.
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

# cd_func is requested even though it overrides the builtin `cd`
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
diffcolor(){ if diff --help 2>&1 | grep -q ' --color'; then command diff --color=auto "$@"; else command diff "$@"; fi; }
alias bdiff='LC_ALL=C diff'

# --- iproute2 color helper ---
ipcolor(){ command -v ip >/dev/null || { echo "ip not found" >&2; return 127; }; command ip -c "$@"; }


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
    for arg in "$@"; do q+=" $(printf '%q' "$arg")"; done
    cmd_str="${q# }"

    # Run the command under a child bash, stamping BEGIN/END
    script -afe "$logfile" bash -lc \
'printf "[runlog] BEGIN %(%F %T %z)T\n" -1
trap '\''rc=$?; printf "[runlog] END rc=%s %(%F %T %z)T\n" "$rc" -1'\'' EXIT
'"$cmd_str"
    rc=$?
  fi
  
  #Make clean copy (ANSI escapes stripped) alongside the raw log
  
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
