#!/usr/bin/env bash

echo "CHARACTER HEXA OCTA"
for i in {0..127}; do
  dec_str="${i}"
  while [ ${#dec_str} -lt 3 ]; do
    dec_str=" ${dec_str}"
  done
  hex_base=$(echo "ibase=10; obase=16; ${i}" | bc)
  while [ ${#hex_base} -lt 2 ]; do
    hex_base="0${hex_base}"
  done
  hex_str="\\x${hex_base}"
  oct_base=$(echo "ibase=10; obase=8; ${i}" | bc)
  while [ ${#oct_base} -lt 3 ]; do
    oct_base="0${oct_base}"
  done
  oct_str="\\${oct_base}"
  kbd_str=""
  the_char=""
  the_char_extra=""
  if [ ${i} -lt 32 -o ${i} -eq 127 ]; then
    if [ ${i} -eq 0 ]; then
      the_char="NULL"
    elif [ ${i} -eq 10 ]; then
      the_char="$'\n'"
    else
      the_char=$(printf %q "$(echo -e ${oct_str})")
      the_char_extra=" "
    fi
    if [ ${i} -eq 10 ]; then
      kbd_str=" $"
    else
      kbd_str=$(echo -ne "${oct_str}" | cat -ETv)
    fi
  else
    the_char=$(printf %b "${oct_str}")
  fi
  while [ ${#the_char} -lt 10 ]; do
    the_char=" ${the_char}"
  done
  while [ ${#kbd_str} -lt 5 ]; do
    kbd_str="${kbd_str} "
  done
  echo "${the_char} ${hex_str} ${oct_str} "\
"${kbd_str} ${dec_str}" | sed 's#\(.\)[$]$#\1#g;'
done
