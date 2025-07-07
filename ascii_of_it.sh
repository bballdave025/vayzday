#!/usr/bin/env bash

echo "CHARACTER  HEXA OCTA KBD-ESC DEC uconv_-x_any-name  ASCII_RFC20_Name"
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
  char_uconv=""
  char_name=""
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
    elif [ ${i} -eq 127 ]; then
      kbd_str="^?"
    else
      kbd_str=$(echo -ne "${oct_str}" | cat -ETv)
    fi
    char_uconv=$(echo -ne "${hex_str}" | uconv -x any-name)
    while [ ${#char_uconv} -lt 18 ]; do
      char_uconv="${char_uconv}"
    done
  else
    the_char=$(printf %b "${oct_str}")
  fi
  while [ ${#the_char} -lt 10 ]; do
    the_char=" ${the_char}"
  done
  while [ ${#kbd_str} -lt 7 ]; do
    kbd_str="${kbd_str} "
  done
  case ${i} in
    0)
      char_name="NUL '\0' (null character)"
      ;;
    1)
      char_name="SOH      (start of heading)"
      ;;
    2)
      char_name="STX      (start of text)"
      ;;
    3)
      char_name="ETX      (end of text)"
      ;;
    4)
      char_name="EOT      (end of transmission)"
      ;;
    5)
      char_name="ENQ      (enquiry)"
      ;;
    6)
      char_name="ACK      (acknowledge)"
      ;;
    7)
      char_name="BEL      (bell)"
      ;;
    8)
      char_name="BS       (backspace)"
      ;;
    9)
      char_name="HT       (horizontal tab)"
      ;;
    10)
      char_name="LF       (new line)"
      ;;
    11)
      char_name="VT       (vertical tab)"
      ;;
    12)
      char_name="FF       (form feed)"
      ;;
    13)
      char_name="CR       (carriage ret)"
      ;;
    14)
      char_name="SO       (shift out)"
      ;;
    15)
      char_name="SI       (shift in)"
      ;;
    16)
      char_name="DLE      (data link escape)"
      ;;
    17)
      char_name="DC1      (device control 1)"
      ;;
    18)
      char_name="DC2      (device control 2)"
      ;;
    19)
      char_name="DC3      (device control 3)"
      ;;
    20)
      char_name="DC4      (device control 4)"
      ;;
    21)
      char_name="NAK      (negative ack.)"
      ;;
    22)
      char_name="SYN      (synchronous idle)"
      ;;
    23)
      char_name="ETB      (end of trans. blk)"
      ;;
    24)
      char_name="CAN      (cancel)"
      ;;
    25)
      char_name="EM       (end of medium)"
      ;;
    26)
      char_name="SUB      (substitute)"
      ;;
    27)
      char_name="ESC      (escape)"
      ;;
    28)
      char_name="FS       (file separator)"
      ;;
    29)
      char_name="GS       (group separator)"
      ;;
    30)
      char_name="RS       (record separator)"
      ;;
    31)
      char_name="US       (unit separator)"
      ;;
    32)
      char_name="SPACE"
      ;;
    127)
      char_name="DEL      (erase/obliterate[1])"
      ;;
    *)
      char_name=""  # Not a control (or useful-to-have-named space) char
      ;;
  esac
  while [ ${#char_name} -lt 25 ]; do
    char_name="${char_name} "
  done
  echo "${the_char} ${hex_str} ${oct_str} "\
"${kbd_str} ${dec_str} ${char_uconv} ${char_name}"
done

# echo
# echo
# echo
# echo
# echo "[1] (This is included, because DWB has always wondered.)"
# echo "From ref=\"https://web.archive.org/web/20250706173518/\"\\"
# echo "\"https://datatracker.ietf.org/doc/html/rfc20\""
# echo "Section 5.2"
# echo ">    DEL (Delete): This character is used primarily to \"erase\" or"
# echo "> \"obliterate\" erroneous or unwanted characters in perforated tape."
# echo "> (In the strict sense, DEL is not a control character.)"
# echo
# echo "Also, from the Wikipedia Article on \"Delete character\""
# echo "archived = \"https://web.archive.org/web/20250706180611/\\\""
# echo "\"https://en.wikipedia.org/wiki/Delete_character\""
# echo "we learn \"It is denoted as ^? in caret notation[.]\""
# echo
# echo "There's also more elucidating information there"
# echo
# echo "> This code was originally used to mark deleted characters on"
# echo "> punched tape, since any character could be changed to all 1s"
# echo "> by punching holes everywhere. If a character was punched"
# echo "> erroneously, punching out all seven bits caused this position"
# echo "> to be ignored or deleted. In hexadecimal, this is 7F to rub"
# echo "> out 7 bits (FF to rubout 8 bits was used for 8-bit codes)."
# echo "> This character could also be used as padding to slow down"
# echo "> printing after newlines, though the all-zero NUL was more"
# echo "> often used."
# echo ">"
# echo "> The Teletype Model 33 provided a key labelled [RUB OUT] to"
# echo "> punch this character (after the user backed up the tape using"
# echo "> another button), and did not provide a key that produced the"
# echo "> backspace character (BS)."
