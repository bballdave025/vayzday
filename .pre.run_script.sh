#!/bin/bash
#
##############################################################################
# @file  run_script.sh
# @author : David Wallace BLACK   GitHub: @bballdave025
# @since : sometime in 2017-2018, maybe a bit before
#
# This script will start a logfile of an interactive console session.
# It uses the `script` command.
# It automatically names the logfile whose name contains the date and time
# that the `script` command was issued.
# The logfile will be created in the directory referred to by the
#+ `saved_in_dir' variable.
# Each logfile will have as prefix the string referred to by the
#+ `filename_prefix' variable.
#
#############################################################################

filename_prefix="Work_Record_DWB_"
saved_in_dir="$HOME/work_logs/"

if [ ! -d "${saved_in_dir}" ]; then
  mkdir -p "${saved_in_dir}"
fi

working_dir=$(pwd)

current_date_time=$(date +%s_%Y-%m-%dT%H%M%S%z)

fname_base="${saved_in_dir}${filename_prefix}${current_date_time}"
filename="${fname_base}.log"

#would require extra dependencies (wred)#
#wred#scrubbed_filename="${fname_base}_scr2log-1.log"
scrubbed_filename="${fname_base}_clean.log"

script "${filename}"

#would require extra dependencies (wred)#
#wred##$HOME/dwb_bash_util/misc_programs/misc-scripts-20200515/\
#wred#script2log_location="$HOME/"  #  might move into a  util  directory,
#wred#                              #+ but not yet. DWB 2025-07-21
#wred#"${script2log_location}"script2log "${filename}" > \
#wred#"${scrubbed_filename}"

#wred#echo
#wred#echo " The scrubbed file (i.e. the more-readable logfile without all"
#wred#echo " the extra control characters) is"
#wred#echo "${scrubbed_filename}"
#wred#echo

script2log_location="$HOME/"  #  might move into a  util  directory,
scrscr_location="${HOME}/"    #+ but not yet. DWB 2025-07-21

echo
echo " The raw file spat out by typescript is at"
echo "${filename}"
echo
echo " Suggested next steps for cleaning are:"

thr_step_fname="${fname_base}_scrscr-3"
echo "$HOME/script_scrubber.sh ${scrubbed_filename} ${thr_step_fname}"
fin_step_fname=$(echo "${sec_step_fname}" | \
                   sed 's#^\(.*\)\([.][^.]\{1,6\}\)$#\1_fin-4\2#g')
#instead of '_fin-4', used to call it#         _outcaretH-3
echo " then"
echo " (where you get '^H' by using |_Ctrl_|+|_v_| then |_Ctrl_|+|_h_|)"
echo "sed 's#[^H]\+##g' ${thr_step_fname} > ${fin_step_fname}"
echo " and finally"

echo "cp ${fin_step_fname} ${scrubbed_filename}"

cd "${working_dir}"
