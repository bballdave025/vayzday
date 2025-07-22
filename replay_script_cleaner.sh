#!/usr/bin/env bash
#
# @file   : replay_script_cleaner.sh
# @author : GitHub @Stéphane-Chazelas unix.stackexchange.com/a/631927/291375
#           I, GitHub @bballdave025, tweaked a few things to make results
#           match my preferences, but the workhorse is only slightly changed
# @since  : 2025-07-21  A date on which I haven't tested very much, at all

orig_filename="typescript"
if [[ $# -eq 0 ]]; then :
elif [[ $# -ge 1 ]]; then
  orig_filename="$1"  # ignoring all but first argument
else
  echo "You've really messed something up. n_args < 0" >&2
  exit -1
fi

if [ ! -e "${orig_filename}" ]; then
  echo -e "The filename you gave,\n${orig_filename}" >&2
  echo -e "\ndoesn't exist." >&2
  exit 1
fi

scrubbed_filename="${orig_filename}.clean"
#n_lines=$(wc -l < "${orig_filename}")
#n_scrollback=$(echo "${n_lines}*2+50000" | bc)  # plenty safe ...
#  ... but I'm pretty sure it doesn't get passed into the subshell
#  The following is almost straight from @Stéphane-Chazelas (see Note 2)
INPUT="${orig_filename}" OUTPUT="${scrubbed_filename}" screen -Dmc /dev/null \
    sh -c 'screen -X scrollback 500000
           cat < "${INPUT}"
           screen -X hardcopy -h "${OUTPUT}"'

#  More fluff added by @bballdave025
echo -e "The cleaned terminal I/O log is now at\n  '${scrubbed_filename}'"
echo "The raw output of  script  still exists; remove if desired with"
echo "  rm -f ${orig_filename}"
