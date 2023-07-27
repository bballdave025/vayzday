#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-

##############################################################################
'''
@file: dwb_fh_spec.py
@author : David Wallace Black
         uname: bballdave025; server: yahoo -d-o-t- com
       OR
         uname: thedavidwblack; server: gmail -d-o-t- com 
@since :  2020-03-31
@ref : "https://www.ling.upenn.edu/courses/Spring_2003/" + \
       "ling538/UnicodeRanges.html"
       (archived)
       "https://web.archive.org/web/20200403204117/" + \
       "https://www.ling.upenn.edu/courses/Spring_2003/" + \
       "ling538/UnicodeRanges.html"
       (which is really just a nice way to get to specific pages also
        available via the official Unicode site, i.e.)
       "http://www.unicode.org/charts/PDF/"
         OR (with a different, thematically-and-alphabetically-sorted
         interface)
       "http://www.unicode.org/charts/"
'''
##############################################################################

import os
import sys
import re
import unicodedata


def main(to_ascii_clean_str):
  '''
  Easy access to the cleaning functionality from the command line.
  '''
  
  return run(to_ascii_clean_str)

##endof:  def main(to_ascii_clean_str)


def run(to_ascii_clean_str):
  '''
  Easy-to-remember method name for getting the cleaning functionality
  '''
  
  return dwb_fh_spec_process(to_ascii_clean_str)
  
##endof:  run(to_ascii_clean_str)


def dwb_fh_spec_process(to_ascii_clean_str):
  '''
  Does specific text processing for Dave BLACK's file download strings
  
  @param  to_ascii_clean_str  :  The string that should be cleaned
  @returns  A string that has been cleaned.
  '''
  
  processing_str = to_ascii_clean_str
  
  if processing_str.startswith(r"Video_by"):
    processing_str = processing_str + "-inst"
  
  processing_str = re.sub(u"\u0042\u0045\u004c\u004c\u0059",
                          u"\u0042",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"(^|_)\u0048\u004f\u0054" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"(^|_)\u0053\u0045\u0058\u0059" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"(^|_)\u0053\u0045\u0058\u0055\u0041\u004c" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"(^|_)\u0053\u0045\u0058" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"(^|_)\u0053\u0045\u004b\u0053" + \
                          u"\u0055\u0041\u004c" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"(^|_)\u0053\u0045\u004b\u0053" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"(^|_)\u0042\u004f\u004f\u0042" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"(^|_)\u0042\u0052\u0045\u0041\u0053\u0054" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"(^|_)\u0054\u0049\u0054" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"(^|_)\u0042\u004f\u0055\u004e\u0043" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  
  processing_str = re.sub(u"(^|_)\u0042\u004f\u0055\u004e\u0043" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"(^|_)\u0042\u004f\u0055\u004e\u0043" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"(^|_)\u0042\u004f\u0055\u004e\u0043" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  
  processing_str = re.sub(u"(^|_)\u0063\u006c\u0065\u004e\u0043" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  
  processing_str = re.sub(u"(^|_)\u0043\u004c\u0045\u0041" + \
                          "\u0056\u0043\u0047\u0045" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"\u0043\u004c\u0045\u0041\u0056",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"(^|_)\u0042\u004f\u004c\u004c" + \
                          "\u0059\u0057\u004f\u004f\u0044" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"\u0042\u004f\u004c\u004c\u0059",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  
  processing_str = re.sub(u"(^|_)\u004a\u0049\u0047\u0047\u004c" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"(^|_)\u0042\u0055\u0053\u0054\u0059" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"\u0054\u0052\u0059\u0041\u0053\u004b",
                          u"\u006b\u0061\u0072\u0074\u0079\u0073",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"\u005a\u0048\u0049\u0056\u004f\u0054" + \
                          "(_|$|[a-z0-9])",
                          "Z\1",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"(^|_)\u0047\u0052\u0055\u0044" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"(^|_)\u0056\u004f\u0053\u0054" + \
                          u"\u004f\u0043\u0048" + \
                          "(_|$|[a-z0-9])",
                          "\1V\2",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"\u0042\u004f\u0055\u004e\u0043" + \
                          "(_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  processing_str = re.sub(u"\u0053\u0048\u0041\u004b" + \
                          "[EeIiYy](_|$|[a-z0-9])",
                          "_",
                          processing_str,
                          flags=re.IGNORECASE)
  
  processing_str = re.sub(u"\u0042\u0055\u004e\u004e\u0059",
                          "b",
                          processing_str,
                          flags=re.IGNORECASE)

  processing_str = re.sub(u"^\u0065\u0073\u0074_",
                          "",
                          processing_str)
  
  return processing_str
  
##endof:  dwb_fh_spec_process(to_ascii_clean_str)

if __name__ == "__main__":
  '''
  Gets run if the script is called from the command line
  '''
  
  main(sys.argv[1]) # Should take string as input.

##endof:  if __name__ == "__main__"
