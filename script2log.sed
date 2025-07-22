# @file : script2log.sed
# @source : InvisibleIsland (see also script2log - sh script)
#           Source for this  sed  script was downloaded at
# sed_src_url="https://invisible-island.net/scripts/#download"
# with the Special-purpose tarball (misc-scripts.tar.gz)
# archived_to_links="https://web.archive.org/web/20241201163415/"\
#"https://invisible-island.net/scripts/#download"
# archived_download_link="https://web.archive.org/web/20250721142952/"\
#"https://invisible-island.net/datafiles/release/misc-scripts.tar.gz"
# @date-downloaded : 2025-07-20
# Called from  script2log  (the  sh  script), which has usage
# instructions.
##### ENDOF BBALLDAVE025 COMMENTS #####
# $Id: script2log.sed,v 1.3 2015/02/04 23:50:12 tom Exp $
#
# Trim ordinary ANSI sequences, then OSC sequences, then backspace
# sequences, then trailing CR's and finally overstruck sections of
# lines.
#
# There are still several interesting cases which cannot be handled
# with a script of this sort.  For example:
#	CSI K (clear line)
#	cursor movement within the line
s/[[][<=>?]\{0,1\}[;0-9]*[@-~]//g
s/[]][^]*//g
s/[]][^]*\\//g
:loop
s/[^]\(.\)/\1/g
t loop
s/*$//g
s/^.*//g
s/[^[]//g
