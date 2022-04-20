# .bash_functions

##DWB 2022-02-26, renamed these files and moved them in here

if [ -f "${HOME}/.USER_bash_functions" ]; then
  source "${HOME}/.USER_bash_functions"
fi

if [ -f "${HOME}/.git_bash_functions" ]; then
  source "${HOME}/.git_bash_functions"
fi
