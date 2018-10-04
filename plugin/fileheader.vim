" @Author: ahonn <ahonn95@outlook.com>
" @Date: 2018-10-03 23:21:37
" @Last Modified by:  <ahonn95@outlook.com>
" @Last Modified time: 2018-10-04 20:39:57

if !exists('g:fileheader_auto_add')
  let g:fileheader_auto_add = 0
endif

if !exists('g:fileheader_auto_update')
  let g:fileheader_auto_update = 1
endif

if !exists('g:fileheader_author')
  let g:fileheader_author = ''
endif

if !exists('g:fileheader_email')
  let g:fileheader_email = ''
endif

if !exists('g:fileheader_show_email')
  let g:fileheader_show_email = 1
endif

if !exists('fileheader_by_git_config')
  let g:fileheader_by_git_config = 1
endif

if !exists('g:fileheader_new_line_at_end')
  let g:fileheader_new_line_at_end = 1
endif

if !exists('g:g:fileheader_delimiter_map')
  let g:fileheader_delimiter_map = {}
endif

if g:fileheader_auto_add
  autocmd BufRead * call fileheader#add_file_header()
endif

if g:fileheader_auto_update
  autocmd BufWritePre * call fileheader#update_file_header()
endif

if g:fileheader_by_git_config == 1
  autocmd VimEnter * call fileheader#load_git_config()
endif

command! -range=% AddFileHeader call fileheader#add_file_header()
command! -range=% UpdateFileHeader call fileheader#update_file_header()
