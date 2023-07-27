#/bin/bash
#
##############################################################################
# @file : rename_inst_files.sh
# @author : D Black
# @since : 2020-06-12
#
#
##############################################################################

do_debug=0
do_verbose=1

dirname_with_inst="$1"

[ -z "${dirname_with_inst}" ] && dirname_with_inst="."

dirname_with_inst="$(realpath ${dirname_with_inst})"

if [ $do_debug -eq 1 ]; then
  echo "--------------------------------------------------------------------"
  echo
  echo -e "dirname_with_inst:\n${dirname_with_inst}"
fi ##endof:  if [ $do_debug -eq 1 ]

out_fname_list="insts_to_rename_$(date +'%s').lst"
out_fpath_list="${dirname_with_inst}/${out_fname_list}"

if [ $do_debug -eq 1 ]; then
  echo
  echo -e "out_fpath_list:\n${out_fpath_list}"
fi ##endof:  if [ $do_debug -eq 1 ]

find "${dirname_with_inst}" -mindepth 1 -maxdepth 1 -type f -name "*.mp4" \
  -print0 | xargs -I'{}' -0 echo "{}" >> "${out_fpath_list}"

while read -r line; do
  if [ $do_debug -eq 1 ]; then
    echo
    echo "---------------------------------------------"
  fi ##endof:  if [ $do_debug -eq 1 ]
  
  ## reading in "${out_fpath_list}"
  this_fname="${line}"
  
  ## Have to run it on stupid Windows ffmpeg
  this_win_fname=$(cygpath -w "${this_fname}")
  
  this_res=$(ffprobe -v error -select_streams v:0 \
      -show_entries stream=width,height -of csv=s=x:p=0 \
        "${this_win_fname}")
  
  this_res=$(echo "${this_res}" | sed 's#[^0-9x]##g')
  
  if [ $do_debug -eq 1 ]; then
    echo -e "this_fname:\n${this_fname}"
    echo "this_res: ${this_res}"
  fi ##endof:  if [ $do_debug -eq 1 ]  
   
  code_and_ext=$(echo "${this_fname}" | \
                   sed 's#^.*[^-][-]\([^.]\{10,12\}[.]mp4\)$#\1#g')
  code_len=$(echo "${#code_and_ext}-4" | bc)
  
  if [ $do_debug -eq 1 ]; then
    echo
    echo "Original:"
    echo "code_and_ext: ${code_and_ext}"
    echo "code_len: ${code_len}"
  fi ##endof:  if [ $do_debug -eq 1 ]
  
  new_code_and_ext="${code_and_ext}"
  new_code_len=$(echo "${#new_code_and_ext}-4" | bc)
  while [ $new_code_len -lt 11 ]; do
    new_code_and_ext="Y${new_code_and_ext}"
    new_code_len=$(echo "${#new_code_and_ext}-4" | bc)
  done ##endof:  while [ $code_len -lt 11 ]
  
  this_new_win_fname=$(echo "${this_win_fname}" | \
         sed 's#'"${code_and_ext}"'#'"${new_code_and_ext}"'#g')
  this_new_cyg_fname=$(cygpath "${this_new_win_fname}")
  
  if [ $do_debug -eq 1 ]; then
    echo
    echo "After:"
    echo "new_code_and_ext: ${new_code_and_ext}"
    echo "new_code_len: ${new_code_len}"
    echo -e "this_new_win_fname:\n${this_new_win_fname}"
    echo -e "this_new_cyg_fname:\n${this_new_cyg_fname}"
  fi ##endof:  if [ $do_debug -eq 1 ]
  
  this_new_bare_fname=$(echo "${this_new_cyg_fname}" | \
                                         awk -F'/' '{print $NF}')
  
  this_cyg_file_dir=$(echo "${this_new_cyg_fname}" | \
                           sed 's#^\(.*\)/[^/]\+$#\1#g')
  if [ $do_debug -eq 1 ]; then
    echo
    echo "this_new_bare_fname: ${this_new_bare_fname}"
  fi ##endof:  if [ $do_debug -eq 1 ]
  
  is_best="True"
  used_fname=$(python3 -u rus_greek_etc_to_ascii.py \
                "${this_new_bare_fname}" \
                  "${is_best}" "${this_res}" 2>&1)
  
  new_fname="${this_cyg_file_dir}/${used_fname}"
  
  if [ $do_verbose -eq 1 ]; then
    echo "used_fname: ${used_fname}"
    echo
    echo " Attempting to copy"
    echo "this_fname: ${this_fname}"
    echo " TO"
    echo "new_fname: ${new_fname}"
  fi ##endof:  if [ $do_debug -eq 1 ]
  
  cp "${this_fname}" "${new_fname}" || \
                echo -e "\n\nProblem with: ${this_fname}\n\n" >&2
done < "${out_fpath_list}"
     ##endof:  while read -r line

echo
echo "Check that the filenames renamed correctly"
echo "If they did, you can run the command:"
echo "while read -r line; do rm \"\${line}\"; done < \"${out_fpath_list}\""
echo "to remove the originals."
echo "If you want, you can also remove the list of originals:"
echo "rm \"${out_fpath_list}\""
echo " ... I would do it."
echo
