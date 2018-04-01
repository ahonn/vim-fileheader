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
  let g:fileheader_by_git_config = 1 " TODO
endif

if !exists('g:fileheader_new_line_at_end')
  let g:fileheader_new_line_at_end = 1
endif

let s:delimiter_map = {
  \ 'vim': { 'begin': '"', 'char': '" ', 'end': '"' },
  \ 'javascript': { 'begin': '/**', 'char': ' * ', 'end': ' */' },
  \ }

let g:fileheader_delimiter_map = s:delimiter_map

if exists('g:fileheader_delimiter_map')
  call extend(s:delimiter_map, g:fileheader_delimiter_map)
endif
