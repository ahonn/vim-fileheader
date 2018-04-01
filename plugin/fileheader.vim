if !exists('g:fileheader_auto_add')
  let g:fileheader_auto_add = 0
endif

if !exists('g:fileheader_auto_update')
  let g:fileheader_auto_update = 1
endif

if !exists('g:fileheader_default_author')
  let g:fileheader_default_author = ''
endif

if !exists('g:fileheader_default_email')
  let g:fileheader_default_email = ''
endif

if !exists('g:fileheader_show_email')
  let g:fileheader_show_email = 1
endif

if !exists('fileheader_by_git_config')
  let g:fileheader_by_git_config = 0
endif

if !exists('g:fileheader_new_line_at_end')
  let g:fileheader_new_line_at_end = 1
endif

let s:vim_style = { 'begin': '"', 'char': '" ', 'end': '"' }
let s:c_style = { 'begin': '/**', 'char': ' * ', 'end': ' */' }
let s:delimiter_map = {
  \ 'vim': s:vim_style,
  \ 'javascript': s:c_style,
  \ }

let g:fileheader_delimiter_map = s:delimiter_map

if exists('g:fileheader_delimiter_map')
  call extend(s:delimiter_map, g:fileheader_delimiter_map)
endif

" autocmd
if g:fileheader_auto_add
  autocmd BufNewFile * AddFileHeader
endif

if g:fileheader_auto_update
  autocmd BufWritePre * UpdateFileHeader
endif
