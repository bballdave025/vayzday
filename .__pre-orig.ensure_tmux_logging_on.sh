#!/usr/bin/env bash
#
# @file : ~/.ensure_tmux_logging_on.sh

### changed for auto-logging, bballdave025 2022-03-07
#orig#CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#orig#
#orig#source "$CURRENT_DIR/variables.sh"
#orig#source "$CURRENT_DIR/shared.sh"

## new for tmux auto-logging, bballdave025 2022-02-28
TMUX_LOGGING_SCRIPTS_DIR="$HOME/.tmux/plugins/tmux-logging/scripts"
CURRENT_DIR="$TMUX_LOGGING_SCRIPTS_DIR"
  ## Not really our current dir, but it allows other code called
  ##+ further on (in the tmux-logging scripts) to work correctly.

source "$TMUX_LOGGING_SCRIPTS_DIR/variables.sh"
source "$TMUX_LOGGING_SCRIPTS_DIR/shared.sh"

start_pipe_pane() {
  local file=$(expand_tmux_format_path "${logging_full_filename}")
  "$CURRENT_DIR/start_logging.sh" "${file}"
  display_message "Started logging to ${logging_full_filename}"
  ### Back to orig ( -^- ) 2022-03-24 #// DWB changed -v- 2022-03-23
  #display_message -p \
  #  ": :: Started logging to ${logging_full_filename}"
}

### original function commented out, bballdave025 2022-03-07
#stop_pipe_pane() {
# tmux pipe-pane
# display_message "Ended logging to $logging_full_filename"
#}

### new function added, bballdave025 2022-02-28
confirm_logging()
{
  display_message "Logging already happening to ${logging_full_filename}"
  ### Back to orig ( -^- ) 2022-03-24 #// DWB changed -v- 2022-03-23
  #display_message -p \
  #  ": :: Logging already happening to ${logging_full_filename}"
}

# returns a string unique to current pane
pane_unique_id() {
  tmux display-message -p "#{session_name}_#{window_index}_#{pane_index}"
}

# saving 'logging' 'not logging' status in a variable unique to pane
set_logging_variable() {
  local value="$1"
  local pane_unique_id="$(pane_unique_id)"
  tmux set-option -gq "@${pane_unique_id}" "$value"
}

# this function checks if logging is happening for the current pane
is_logging() {
  local pane_unique_id="$(pane_unique_id)"
  local current_pane_logging="$(get_tmux_option "@${pane_unique_id}" "not logging")"
  if [ "$current_pane_logging" == "logging" ]; then
    return 0
  else
    return 1
  fi
}

#original comment# starts/stop logging
# starts/continues logging ( bballdave025, 2022-02-28 )
#orig#toggle_pipe_pane() {
## -v- new function name -v- , bballdave025, 2022-03-09
ensure_pipe_pane_on()
{
if is_logging; then
    #orig#set_logging_variable "not logging"
    #orig#stop_pipe_pane
    #bbd025 note: you could simply put one character, `:' for this `if' part
    # -v- bballdave025 2022-02-28 -v- first line probably unneeded (?)
    set_logging_variable "logging"
    confirm_logging
  else
    set_logging_variable "logging"
    start_pipe_pane
  fi
}

## -v- main changed -v- by bballdave025, 2022-03-08
#orig#main() {
#orig#  if supported_tmux_version_ok; then
#orig#    toggle_pipe_pane
#orig#  fi
#orig#}

main()
{
  if supported_tmux_version_ok; then
    ensure_pipe_pane_on
  fi
}
main
