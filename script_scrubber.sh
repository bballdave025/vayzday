#!/usr/bin/env bash
#
##############################################################################
# @file : script_scrubber.sh
# @author : David Wallace BLACK   GitHub: @bballdave025
# @since : sometime in 2017-2018, maybe a bit before
# @last-big-modification : 2025-07-21
#
# See the usage variable
#
##############################################################################

usage="Usage is:\n % script_scrubber.sh <unscrubbed-file> "\
"[<alternate-filename>]\n"\
"If no <alternate-filename> argument is given, the <unscrubbed-file> \n"\
"will be cleaned in place.\n"\
"If '-' is given as the second argument, the text of the cleaned\n"\
"file will be outputted to the terminal (stdout) and can be\n"\
"redirected, as with \n"\
"      ' - > <new-filename>', \n"\
"      ' - | tee <new-filename>',\n"\
"etc.\n"
"\nThis script takes the output of the Linux script command and cleans"\
"control characters and other unwanted artifacts."\
"It uses output_scrubbed_text.pl\n"
scrubber_path="$HOME"
scrubber_location="${scrubber_path}/output_scrubbed_text.pl"
if [[ ! -f "${scrubber_location}" ]]; then
  echo -e "Fatal error! ${scrubber_location} does not exist."
  exit 1
fi #endof:  if [[ -f "${location}/output_scrubbed_text.pl" ]]
if [[ ! -x "${scrubber_location}" ]]; then
  chmod +x "${scrubber_location}"
fi #endof:  if [[ ! -x "${scrubber_location}" ]]
if [[ $# -eq 0 ]]; then
  echo "No argument given." >&2
  echo -e "${usage}" >&2
  exit 2
elif [[ $# -eq 1 ]]; then
  if [[ $1 -eq "--help" ]]; then
    echo -e "${usage}"
    exit 0
  else
    "${scrubber_location}" $1 > tmp && mv tmp $1
  fi #endof:  if [[ $1 -eq "--help" ]]
elif [[ $# -eq 2 ]]; then
  if [[ $2 -eq "-" ]]; then
    "${scrubber_location}" $1 1> /dev/stdout  # very explicitly to stdout
  else
    "${scrubber_location}" $1 > $2
  fi #enodf:  if/else [[ $2 -eq "-" ]]
else
  if [[ $2 -eq "-" ]]; then
    "${scrubber_location}" $1 1> /dev/stdout  # very explicitly to stdout
  else
    echo "More than two arguments given without output" >&2
    echo "going to stdout." >&2
    echo -e "${usage}" >&2
  fi #endof:  if/else [[ $2 -eq "-" ]]
fi #endof:  if [[ $# -eq <0,1,2,else> ]]
