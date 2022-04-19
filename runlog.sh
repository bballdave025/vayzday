#!/bin/bash
#
##############################################################################
# @file run_script.sh
#
# bballdave025
#
# This script will start a logfile of an interactive console session.
#+ It uses the `script' command.
#+ It automatically names the logfile whose name contains the date and time
#+  that the `script' command was issued.
#+ The logfile will be created in directory assigned to `saved_in_dir'
#+ Each log is prefixed with the string assigned to `filename_prefix'
# 
#+ It's very useful to use this with `script_scrubber.sh' , which calls
#+  `output_scrubbed_script.pl'
#+  ref="https://unix.stackexchange.com/a/18979"
#+   for `output_scrubbed_script.pl'
#+ It can also be used with (in my case, a modified version of) the
#+  `script2log' (sh) script originally written by the maintainer of 
#+  Invisible Island ( @todo get Inivisible Island info and URL )
#+
#+ To specify which should be used, change the values of the variables
#+  `do_use_script2log' and `do_use_script_scrubber'
#############################################################################

filename_prefix="Work_Record_DWB_"
saved_in_dir="$HOME/work_logs/"

working_dir=$(pwd)

current_date_time=$(date +%s_%Y%m%dT%H%M%S%z)

fname_base="${saved_in_dir}${filename_prefix}${current_date_time}"
filename="${fname_base}.log"

do_use_script2log=1
dir_of_script2log="$HOME/dwb_bash_util/misc_programs"\
"/misc-scripts-20200515/"
path_2_script2log="${dir_of_script2log}/script2log"
do_have_script2log=$(type ${path_2_script2log} && \
                                          echo "1" || echo "0")

do_use_script_scrubber=1
dir_of_script_scrubber="$HOME/"
path_2_script_scrubber="${dir_of_script_scrubber}/scriptscrubber"
do_have_script_scrubber=$(type ${path_2_script_scrubber} && \
                                          echo "1" || echo "0")

scrubbed_fname_base=''
scrubbed_fname=''

script2log_will_be_used=0
script2log_wanted_not_found=0
script_scrubber_will_be_used=0
script_scrubber_wanted_not_found=0

if [ -z "${scrubbed_fname}" -a $do_use_script2log -eq 1 ]; then
  if [ $do_have_script2log -eq 1 ]; then
    scrubbed_fname_base="${fname_base}_scrubbed_s2l"
    script_scrubber_will_be_used=1
  else
    script_scrubber_wanted_not_found=1
    # maybe output an error, eventually
  fi ##endof:  if/else [ $do_have_script2log -eq 1 ]
fi ##endof:  if [ -z "${scrubbed_fname}" -a $do_use_script2log -eq 1 ]

if [ $do_use_script_scrubber -eq 1 ]; then
  if [ $do_have_script_scrubber -eq 1 ]; then
    script_scrubber_will_be_used=1
    if [ -z "${scrubbed_fname}" ]; then
      scrubbed_fname_base="${fname_base}_scrubbed_scsc"
    else
      scrubbed_fname_base="${scrubbed_fname_base}_scsc"
    fi ## endof:  if/else [ -z "${scrubbed_fname}" ]
  fi ##endof:  if [ $do_have_script_scrubber -eq 1 ]
else
  script_scrubber_wanted_not_used=1
  # maybe output an error, eventually
fi #endof:  if/else [ $do_use_script_scrubber -eq 1 ]

if [ ! -z "${scrubbed_fname_base}" ]; then
  scrubbed_fname="${scrubbedfame_base}.log"
fi

script "${filename}"

# At this point, the subshell created by `script' will have been
#+ exited cleanly, and the logfile, `${filename}' will have been
#+ created. A message stating as much will have been outputted.

echo
echo " # If you do not see a message about the script finishing,"
echo " #+ which should also give the name of the output file,"
echo " #+ you have a problem, and some errors unforeseen by this"
echo " #+ script will likely come up."
echo

cd "${working_dir}"

if [ $script2log_wanted_not_used -eq 1 ]; then
  echo "script2log was requested, but could not be located" >&2
fi

if [ $script2log_will_be_used -eq 1 ]; then
  path_2_script2log "${filename}" > "${scrubbed_fname}"
fi

if [ $script_scrubber_wanted_not_used -eq 1 ]; then
  echo "script_scrubber was requested, but could not be located" >&2
fi

if [ $script_scrubber_will_be_used -eq 1 ]; then
  if [ $script2log_will_be_used -eq 1 ]; then
    path_2_script_scrubber "${scrubbed_fname}" tmpscrubbedadd &&
           mv tmpscrubbedadd "${scrubbed_fname}"
  else
    path_2_script_scrubber "${filename}" tmpscrubbed &&
           mv tmpscrubbed "${scrubbed_fname}"
  fi ##endof:  if/else [ $script2log_will_be_used -eq 1 ]
fi ##endof:  if [ $script_scrubber_will_be_used -eq 1 ]

#1## Uncomment (e.g.  `sed -i 's|#1#||g;' run_log.sh' to automate #1#
#1##+ use with `script2log' #1#
#1## @todo  (upload and then) link upload #1#
#1##+ of the sh script as modified by bballdave025
#1##
#1#dir_of_script2log="$HOME/dwb_bash_util/misc_programs"\
#1#"/misc-scripts-20200515/"
#1#"${dir_of_script2log}"/script2log "${filename} > \
#1#"  ${scrubbed_filename}

#2## Uncomment (e.g.  `sed -i 's|#2#||g;' run_log.sh' to automate 
#2##+ use with `script_scrubber.sh' -> `output_scrubbed_script.pl'
#2## @todo  (upload and then) link uploads
#2##+ of the sh and perl scripts from the
#2##+ vayzday repo.
#2#

if [ ! -z "${scrubbed_filename}" ]; then
  echo
  echo " # The scrubbed file (i.e. the more-readable logfile"
  echo " #+ without all the extra control characters) is"
  echo " #+ ${scrubbed_filename}"
  echo
fi
