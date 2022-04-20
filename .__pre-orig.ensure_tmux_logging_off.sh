#!/usr/bin/env bash
#
# @file : ~/.ensure_tmux_logging_off.sh
#
# copied from 
#+  `<base-of-tmux>/plugins/tmux-logging/scripts/toggle_logging.sh'
#+ to my home directory and modified to create an auto-end-logging
#+ thingie

#orig### changed for auto-logging, bballdave025 2022-03-07
#orig#CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#orig#
#orig#source "$CURRENT_DIR/variables.sh"
#orig#source "$CURRENT_DIR/shared.sh"

## new for tmux auto-logging, bballdave025 2022-03-07
TMUX_LOGGING_SCRIPTS_DIR="$HOME/.tmux/plugins/tmux-logging/scripts"
CURRENT_DIR="$TMUX_LOGGING_SCRIPTS_DIR"
  ## Not really our current dir, but it allows other code called
  ##+ further on to work correctly.

source "$TMUX_LOGGING_SCRIPTS_DIR/variables.sh"
source "$TMUX_LOGGING_SCRIPTS_DIR/shared.sh"

### original functions commented out, bballdave025 2022-03-07
#start_pipe_pane() {
# local file=$(expand_tmux_format_path "${logging_full_filename}")
# "$CURRENT_DIR/start_logging.sh" "${file}"
# display_message "Started logging to ${logging_full_filename}"
#}

### new function added, bballdave025 2022-03-07
show_logging_already_off()
{
  display_message "Logging has already been stopped (or was never started)."
  ### Back to orig ( -^- ) 2022-03-24 #// DWB changed -v- 2022-03-23
  #display_message -p \
  #  ": :: Logging has already been stopped (or was never started)."
}

stop_pipe_pane() {
  tmux pipe-pane
  display_message "Ended logging to $logging_full_filename"
  ### Back to orig ( -^- ) 2022-03-24 #// DWB changed -v- 2022-03-23
  #display_message -p \
  #  ": :: Ended logging to $logging_full_filename"
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

#orig comment# starts/stop logging, changed 2022-03-08 to 09, bballdave025
#orig function name#toggle_pipe_pane() {
ensure_pipe_pane_off()
{
  if is_logging; then
    set_logging_variable "not logging"
    stop_pipe_pane
  else
    #orig#set_logging_variable "logging"
    #orig#start_pipe_pane
    #bbd025 note: you could simmply put one character, `:' for this `else' part
    # -v- bballdave025 2022-03-07 -v- first line probably unneeded (?)
    set_logging_variable "not logging"
    show_logging_already_off
  fi
}

main() {
  if supported_tmux_version_ok; then
    #orig#toggle_pipe_pane
    ensure_pipe_pane_off
  fi
}
main
