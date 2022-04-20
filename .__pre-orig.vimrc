
" An example for a vimrc file.
"
" Maintainer: Bram Moolenaar <Bram@vim.org>
" Last change:  2017 Sep 20
"
" To use it, copy it to
"     for Unix and OS/2:  ~/.vimrc
"       for Amiga:  s:.vimrc
"  for MS-DOS and Win32:  $VIM\_vimrc
"     for OpenVMS:  sys$login:.vimrc

" When started as "evim", evim.vim will already have done these settings.
if v:progname =~? "evim"
  finish
endif

" Get the defaults that most users want.
source $VIMRUNTIME/defaults.vim

if has("vms")
  set nobackup    " do not keep a backup file, use versions instead
else
  set backup    " keep a backup file (restore to previous version)
  if has('persistent_undo')
    set undofile  " keep an undo file (undo changes after closing)
  endif
endif

if &t_Co > 2 || has("gui_running")
  " Switch on highlighting the last used search pattern.
  set hlsearch
endif

" Only do this part when compiled with support for autocommands.
if has("autocmd")

  " Use filetype detection and file-based automatic indenting.
  filetype plugin indent on

  " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78

  " Use actual tab chars in Makefiles.
  autocmd FileType make set tabstop=8 shiftwidth=8 softtabstop=0 noexpandtab

  augroup END

else

  set autoindent    " always set autoindenting on

endif " has("autocmd")

"" auto-indent, spaces don't go to tabs, 2 spaces when tab pressed
"" N.B. DWB 20211229. From https://stackoverflow.com/a/323014/6505499
""
"" > Related, if you open a file that uses both tabs and spaces,
"" > assuming you've got
"" >  `set expandtab ts=4 sw=4 ai`
"" > You can replace all the tabs with spaces in the entire file with
"" >
"" > `:%retab`
""
"" Other refs:
"" @ref = 'https://stackoverflow.com/questions/234564/" + \
"" 'tab-key-4-spaces-and-auto-indent-after-curly-braces-in-vim' + \
"" '#comment81949750_323014'
""   > `expandtab` determines if tabs are expanded to spaces.
""   > `ts` = `tabstop` = Number of spaces that a <Tab> in the file
""   >                    counts for.
""   > `sw` = `shiftwidth` = Number of spaces to use for each step
""   >                       of (auto)indent.
""   > `ai` = `autoindent` = Copy indent from current line when
""   >                       starting a new line.
""
"" USED - https://stackoverflow.com/a/21323445/6505499
""        choice 2
""
"filetype plugin indent on

"" Good explanations from https://stackoverflow.com/a/21323445/6505499
""   by @Shervin_Emami
""" These next lines are defaults. The makefile, etc. stuff comes in when
""" a specific file is loaded. From @Shervin_Emami
"" > the 'autocmd FileType make' statement basically tells vim some
"" > settings to use whenever it opens a Makefile. Whereas the
"" > lines below it are setting the defaults. In other words,
"" > the 'tabstop=8 ...' settings are applied later when the
"" > file is opened, and will overwrite the 'tabstop=4 ...'
"" > settings that apply on initialization.
""
""
"" Forget the `else` of that `if/else`
"
"" If it's not a makefile (or anything else we decide
"" should be different, these settings will be used and
"" not overwritten by the choices in filetype
"
set tabstop=2       " The width of a TAB is set to 2.
                    " Still, it is a \t. It is just that
                    " VIM will interpret it to have a
                    " width of 2.
                    " DWB note, 20211229 I'm wanting to
                    " have _only_ spaces. When bringing
                    " files in for use, to keep indents
                    " nice, I'll need to run `:%retab`
                    " on the file.
set shiftwidth=2    " Indents will have a width of 2
set softtabstop=2   " Sets the number of columns for a
                    " TAB at 2 (columns).
set expandtab       " Expand TABs to spaces, i.e. on
                    " pressing tab, insert 2 spaces
set autoindent      " Copy indent from current line when
                    " starting a new line.


" Add optional packages.
"
" The matchit plugin makes the % command work better, but it is not backwards
" compatible.
" The ! means the package won't be loaded right away but when plugins are
" loaded during initialization.
if has('syntax') && has('eval')
  packadd! matchit
endif
