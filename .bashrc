# .bashrc

### From Cygwin /etc/skel/.bashrc
### DWB 2022-03-02
###+ Not using. I think that the `tmux' logging or `screen' might not
###+ work if some job is started in the background. Anyway, the
###+ RHEL8 (Red Hat) doesn't have it or anything like it in
###+ `~/.bashrc', `~/.bash_profile' , `/etc/bashrc' ,
###+ `/etc/bash_profile' , nor in `/etc/profile'
## If not running interactively, don't do anything
#[[ "$-" != *i*  ]] && return

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# User specific environment, though I didn't put this here -DWB 2022-01-11
if ! [[ "$PATH" =~ "${HOME}/.local/bin:${HOME}/bin:" ]]
then
    PATH="${HOME}/.local/bin:${HOME}/bin:$PATH"
fi
export PATH

#Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions

#
# DWB 2022-01-22, User specific environment, for reals
export ORIGINAL_MANPATH="/usr/local/share/man:/usr/share/man"
export ORIGINAL_WITH_ANACONDA_MANPATH=\
"${HOME}/anaconda3/envs/acuss/share/man:"\
"${HOME}/anaconda3/man:"\
"/usr/local/share/man:"\
"/usr/share/man/home/${USER}/anaconda3/envs/acuss/share/man:"\
"${HOME}/anaconda3/man:"\
"/usr/local/share/man:"\
"/usr/share/man"
# DWB as of now, 2022-01-11, "echo $MANPATH" gives nothing.
# I am fixing that
MANPATH=$(man --path)
export MANPATH
#
export ORIGINAL_IFS=" \t\n"
#
#

# for later use inside the settitle, etc. functions
unset PS1ORIG

# set the default editor, now for https://github.com/tmuxinator/tmuxinator
# + DWB, 2022-03-21
export EDITOR='vim'


#
# DWB 2022-01-11, I am not sure where to put this, but I think I will
#                 call it
#
# User customization files to be called.
# Auto-merge the Xresources file, so the xterm changes happen without thinking
[[ -f "${HOME}/.Xresources" ]] && xrdb -merge "${HOME}/.Xresources"
#
#


# DWB 2022-01-22. The following are un-comment-able options from the
# ~/.bashrc created with Cygwin Setup, with the note
# base-files version 4.3-2
##
##
## User dependent .bashrc file
#
## If not running interactively, don't do anything
#[[ "$-" != *i* ]] && return
#
## Shell Options
##
## See man bash for more options...
##
## Don't wait for job termination notification
## set -o notify
##
## Don't use ^D to exit
## set -o ignoreeof
##
## Use case-insensitive filename globbing
## shopt -s nocaseglob
##
## Make bash append rather than overwrite the history on disk
## shopt -s histappend
##
## When changing directory small typos can be ignored by bash
## for example, cd /vr/lgo/apaache would find /var/log/apache
## shopt -s cdspell
#
## Programmable completion enhancements are enabled via
## /etc/profile.d/bash_completion.sh when the package bash_completetion
## is installed.  Any completions you add in ~/.bash_completion are
## sourced last.
#
## History Options
##
## Don't put duplicate lines in the history.
## export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
##
## Ignore some controlling instructions
## HISTIGNORE is a colon-delimited list of patterns which should be excluded.
## The '&' is a special pattern which suppresses duplicate entries.
## export HISTIGNORE=$'[ \t]*:&:[fb]g:exit'
## export HISTIGNORE=$'[ \t]*:&:[fb]g:exit:ls' # Ignore the ls command as well
##
## Whenever displaying the prompt, write the previous line to disk
## export PROMPT_COMMAND="history -a"
##
##

#
# Aliases.
# DWB 2022-01-22, I am including the Cygwin-standard options
# here. After that, I will source my own "${HOME}/.bash_aliases_4_dwb"
#
# Note that I do not like grep and some other things to automatically
# do something other than the built-in behavior.
#
#
#
## For aliases, begin the from-Cygwin part, though I have
## commented/uncommented some parts, DWB 2022-01-11
###
### Some example alias instructions
### If these are enabled they will be used instead of any instructions
### they may mask.  For example, alias rm='rm -i' will mask the rm
### application.  To override the alias instruction use a \ before, ie
### \rm will call the real rm not the alias.
###
### Interactive operation...
### alias rm='rm -i'
alias rmi='rm -i'
### alias cp='cp -i'
alias cpi='cp -i'
### alias mv='mv -i'
alias mvi='mv -i'
###
### Default to human readable figures
### alias df='df -h'
### alias du='du -h'
###
### Misc :)
### alias less='less -r'                          # raw control characters
alias lessraw='less -r'
alias whence='type -a'                            # where, of a sort
### alias grep='grep --color'                     # show differences in colour
#alias grep='/usr/bin/grep'  ## DWB 2022-02-02, built-in
if grep -q "alias" <(type grep) ; then
  unalias grep                ## DWB 2022-02-09, better for built-in
fi
#alias grepcolor='grep --color'
alias grepcolor='grep --color=tty' ## DWB 2022-03-02  Standardize
## DWB 2022-02-02
## colorgrep[.]c?sh is already in /etc/profile.d/
#bad#alias colorgrep='grep --color'
#DWB20220302#alias cgrep='grep --color'
#DWB20220302#alias grepc='grep --color'
alias cgrep='grep --color=auto'    ## DWB 2022-03-02  Standardize
alias grepc='grep --color=auto'
#
### alias egrep='egrep --color=auto'              # show differences in colour
### alias fgrep='fgrep --color=auto'              # show differences in colour
###
### Some shortcuts for different directory listings
### alias ls='ls -hF --color=tty'                 # classify files in colour
#alias ls='/usr/bin/ls'    ## DWB 2022-01-11, built-in
if grep -q "alias" <(type ls) ; then
  unalias ls                ## DWB 2022-02-09, better for built-in
fi
alias lsc='ls --color=auto'
alias lscolor='ls -hF --color=tty'
alias dir='ls --color=auto --format=vertical'
alias vdir='ls --color=auto --format=long'
alias ll='ls -l'                                  # long list
####DWB-previous## alias ll='ls -lah'
### DWB 2022-02-02
alias lh='ls -lah'
alias la='ls -A'                                  # all but . and ..
alias l='ls -CF'
### DWB 2022-03-04, cf. https://unix.stackexchange.com/a/451626/291375
alias ls_name_and_size='ls -Ss1pq --block-size=1'

### DWB 2022-02-26
alias cd..='cd ..' ## for accidental mis-typings
###
###
#

## DWB 2022-02-26. Changing to just source ~/.bash_aliases here. Will
##+ change .bash_aliases_4_dwb to .dblack_bash_aliases and
##+ change .bash_aliases_4_ben_git to .cc_dev_bash_aliases
if [ -f "${HOME}/.bash_aliases" ]; then
  source "${HOME}/.bash_aliases"
fi
##
#if [ -f "${HOME}/.bash_aliases_4_dwb" ]; then
#  source "${HOME}/.bash_aliases_4_dwb"
#fi
##
#if [ -f "${HOME}/.bash_aliases_4_ben_dev" ]; then
#  source "${HOME}/.bash_aliases_4_ben_dev"
#fi
##
#


#
# DWB 2022-01-11, I think I had this as 002 before (directories default
#                 to 775, files to 664) rather than the 022 here
#                 (directories default to 755, files to 644), but
#                 it seems that I had changed it back.
#
#
# Umask
#
# /etc/profile sets 022, removing write perms to group + others.
# Set a more restrictive umask: i.e. no exec perms for others:
# umask 027
# Paranoid: neither group nor others have any perms:
# umask 077
umask 002
#
#


#
# Functions
# DWB 2022-01-11, importing functions from different sources, labeled
#                 as such. Especially with Ben MUJRPHEY's stuff (git and
#                 otherwise), there will be some aliases mixed in with
#                 the functions
#
#
#
## DWB 2022-02-26. Changing to just source ~/.bash_functions here. Will
##+ change .bash_functions_4_dwb to .dblack_bash_functions and
##+ change .bash_functions_4_ben_git to .git_bash_functions
if [ -f "${HOME}/.bash_functions" ]; then
  source "${HOME}/.bash_functions"
fi
##
#if [ -f "${HOME}/.bash_functions_4_dwb" ]; then
#  source "${HOME}/.bash_functions_4_dwb"
#fi
##
#if [ -f "${HOME}/.bash_functions_4_ben_git" ]; then
#  source "${HOME}/.bash_functions_4_ben_git"
#fi
##
#if [ -f "${HOME}/.bash_functions_4_ben_dev" ]; then
#  source "${HOME}/.bash_functions_4_ben_dev" # nothing, for now.
#fi
##
#

#
## DWB 2022-02-02, moving this after the $PS1 stuff (inside the
##+ ~/.bash_functions_4_ben_git file), as suggested in
##+ https://stackoverflow.com/a/58983010/6505499
#
## # DWB 2022-01-22, let us start with the conda stuff
## #
## # >>> conda initialize >>>
## # !! Contents within this block are managed by 'conda init' !!
## __conda_setup="$('/home/Anast/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
## if [ $? -eq 0 ]; then
##     eval "$__conda_setup"
## else
##     if [ -f "${HOME}/anaconda3/etc/profile.d/conda.sh" ]; then
##         . "${HOME}/anaconda3/etc/profile.d/conda.sh"
##     else
##         export PATH="${HOME}/anaconda3/bin:$PATH"
##     fi
## fi
## unset __conda_setup
## # <<< conda initialize <<<
#
#



# DWB 2022-01-11, This will need to be changed as different functions,
#                 aliases, etc. are added here or in any of the alias
#                 or function files sourced above.

alias frombashrc='echo -e "whence                  | runlog \\n"'\
'"dir                     | run_script \\n"'\
'"vdir                    | settitle \\n"'\
'"ll                      | settitlepath \\n"'\
'"la                      |  \\n"'\
'"cd ## cd_func           | gethex4char \\n"'\
'"                        | getbinary4char \\n"'\
'"sudofunc                | getunicode4char \\n"'\
'"sudoadmin               | getbytes4unicode \\n"'\
'"sudoad                  |  \\n"'\
'"                        | htbstr \\n"'\
'"sudo                    | vardebug \\n"'\
'"sudofakefunc            | atree \\n"'\
'"sudofake                | gittracecmd \\n"'\
'"catwithcontrol          | gittracecommand \\n"'\
'"                        |  \\n"'\
'"extsindir               | pythonwin \\n"'\
'"ddate                   | whereispythonstuff \\n"'\
'"tsdate                  |  \\n"'\
'"oldformatdatestr        | npp \\n"'\
'"ofdatecmd               | n++ \\n"'\
'"ofdate                  |  \\n"'\
'"htbstr                  | DAVEHOME \\n"'\
'"vardebug                | WINHOME \\n"'\
'"atree                   | WINDESKTOP \\n"'\
'"                        | APPDATADIR \\n"'\
'"ffmpegwin               | WINPYTHONROOT \\n"'\
'"ffplaywin               | CYGPYTHONROOT \\n"'\
'"ffprobewin              | DAVECYGPROGSPATH \\n"'\
'"ffmpeg                  | DAVEWINPROGSPATH \\n"'\
'"ffplay                  | DAVEWINCPROGSPATH \\n"'\
'"ffprobe                 | ORIGINAL_IFS \\n"'\
'"                        | ORIGINALMANPATH \\n"'\
'"rmi                     |  \\n"'\
'"cpi                     |  \\n"'\
'"grepcolor               |  \\n"'\
'"lscolor                 | "'
#
# Some will need to be taken out, because they were listed for Cygwin
# some will need to be put in, especially Ben's programming and git
# stuff

#
## DWB 2022-01-11, Here's where to make things available by adding them
##                 to the PATH environment variable
#
## dblack's utility stuff to $PATH
export PATH=${HOME}/dwb_bash_util:$PATH
#
#
## Make SCTK available
export PATH=${HOME}/software/external/SCTK/bin:$PATH
#
#
## make invisible island's scripts available, DWB 2022-03-07
export PATH=${HOME}/dwb_bash_util/misc_programs/misc-scripts-20200515/:$PATH

## New script log (interactive terminal log) cleaning method
## DWB 2025-07-21
runscriptreplayclean() {
  filename_prefix="Lab_Notebook_${USER}_"
  saved_in_dir="${HOME}/work_logs/"
  if [ ! -d "${saved_in_dir}" ]; then
    mkdir -p "${saved_in_dir}"
  fi
  current_date_time=$(date +%s_%Y-%m-%dT%H%M%S%z)
  fname_base="${saved_in_dir}${filename_prefix}${current_date_time}"
  filename="${fname_base}.log"
  working_dir=$(pwd)
  script "${filename}"
  n_lines=$(wc -l < "${filename}")
  #n_scrollback=$(echo "${n_lines}*2+50000" | bc)  # plenty safe
  #  plenty safe, but doesn't get passed into subshell
  scrubbed_filename="${fname_base}_clean.log"
  #  Almost straight from
  #+   https://unix.stackexchange.com/a/631927/291375 by @Stéphane-Chazelas
  #+ > Starts a new (`-m') `D'etached screen session ... empty `c'onfig file
  #+ > (`/dev/null'). ... [Inline] `sh' script in `screen' ... increase
  #+ > increase scrollback, ... dump the input file in the `screen' window,
  #+ > then call `hardcopy -h' [with `h'istory] ... [gets us] contents of the 
  #+ > screen including scrollback [dumped] into `$OUTPUT'
  INPUT="${filename}" OUTPUT="${scrubbed_filename}" screen -Dmc /dev/null \
    sh -c 'screen -X scrollback 500000
           cat < "${INPUT}"
           screen -X hardcopy -h "${OUTPUT}"'
  #  took out 'screen -X scrollback ${n_scrollback}', subshell
  echo -e "The cleaned terminal I/O log now at\n  '${scrubbed_filename}'"
  echo "The raw output of  script  still exists; remove if desired with"
  echo "  rm -f ${filename}"
  echo
  cd "${working_dir}"
}

alias runlog='runscriptreplayclean'

## Start tmux-logging for any tmux shell/session
if [ ! -z $TMUX ]; then
  ${HOME}/.ensure_tmux_logging_on.sh
fi


## Function to be run every time one exits a bash terminal.
##+ for now, this is just to close out tmux logging.
##+ ref="https://stackoverflow.com/a/36224134/6505499"
finish()
{
  if [ ! -z $TMUX  ]; then
    ## Logging should already be automoatically on, so we could use
    #$HOME/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh
    ##+ but let's consider it possible that the logging has been
    ##+ turned off, so we'll do an ensure logging off.
    ${HOME}/.ensure_tmux_logging_off.sh
  fi
}

trap finish EXIT
