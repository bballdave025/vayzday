#!/bin/bash
#
##############################################################################
# @file  run_script.sh
# 
# bballdave025
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

working_dir=$(pwd)

current_date_time=$(date +%s_%Y%m%dT%H%M%S%z)

fname_base="${saved_in_dir}${filename_prefix}${current_date_time}"
filename="${fname_base}.log"

#would require extra dependencies (wred)#
#wred#scrubbed_filename="${fname_base}_scrubbed.log"

script "${filename}"

#would require extra dependencies (wred)#
#wred#$HOME/dwb_bash_util/misc_programs/misc-scripts-20200515/\
#wred#script2log "${filename}" > "${scrubbed_filename}"

#wred#echo
#wred#echo " The scrubbed file (i.e. the more-readable logfile without all"
#wred#echo " the extra control characters) is"
#wred#echo "${scrubbed_filename}"
#wred#echo

cd "${working_dir}"
