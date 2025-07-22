#!/usr/bin/env perl
#
##############################################################################
# @file : output_scrubbed_script.pl
# @author : David Wallace BLACK   GitHub: @bballdave025
# @since : sometime in 2017-2018, maybe a bit before
#
# Okay, I found this all over the internet, it's just my favorite.
# One source:
# archived_src=""
# This removes all unwanted junk (control characters, etc) from the output
# of the Linux script command.
# It's imperfect. It struggles with vim, and it doesn't do too well with up
# arrows and tab completion, but I can usually at least see and understand
# what I did.
#
##############################################################################

while (<>)
{
    s/ \e[ #%()*+\-.\/]. |
       \r | # Remove extra carriage returns also
       (?:\e\[|\x9b) [ -?]* [@-~] | # CSI ... Cmd
       (?:\e\]|\x9d) .*? (?:\e\\|[\a\x9c]) | # OSC ... (ST|BEL)
       (?:\e[P^_]|[\x90\x9e\x9f]) .*? (?:\e\\|\x9c) | # (DCS|PM|APC) ... ST
       \e.|[\x80-\x9f] //xg;
       1 while s/[^\b][\b]//g; #remove all non-backspace followed by backspace
    print;
}
