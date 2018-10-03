" @Author: ahonn <ahonn95@outlook.com>
" @Date: 2018-10-03 23:21:37
" @Last Modified by: ahonn <ahonn95@outlook.com>
" @Last Modified time: 2018-10-03 23:26:21

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

let s:vim_style = { 'begin': '', 'char': '" ', 'end': '' }
let s:c_style = { 'begin': '/*', 'char': ' * ', 'end': ' */' }
let s:sass_style = { 'begin': '', 'char': '// ', 'end': '' }
let s:shell_style = { 'begin': '', 'char': '# ', 'end': '' }
let s:haskell_style = { 'begin': '', 'char': '-- ', 'end': '' }
let s:html_style = { 'begin': "<!--", 'char': ' ', 'end': '-->' }
let s:erlang_style = { 'begin': '', 'char': '% ', 'end': '' }
let s:lisp_style = { 'begin': '', 'char': ';; ', 'end': '' }
let s:delimiter_map = {
  \ 'vim': s:vim_style,
  \ 'c': s:c_style,
  \ 'cpp': s:c_style,
  \ 'java': s:c_style,
  \ 'cs': s:c_style,
  \ 'go': s:c_style,
  \ 'objc': s:c_style,
  \ 'swift': s:c_style,
  \ 'javascript': s:c_style,
  \ 'javascript.jsx': s:c_style,
  \ 'typescript': s:c_style,
  \ 'css': s:c_style,
  \ 'less': s:c_style,
  \ 'sass': s:sass_style,
  \ 'scss': s:sass_style,
  \ 'shell': s:shell_style,
  \ 'python': s:shell_style,
  \ 'ruby': s:shell_style,
  \ 'yaml': s:shell_style,
  \ 'toml': s:shell_style,
  \ 'haskell': s:haskell_style,
  \ 'lua': s:haskell_style,
  \ 'html': s:html_style,
  \ 'xml': s:html_style,
  \ 'erlang': s:erlang_style,
  \ 'clojure': s:lisp_style,
  \ 'scheme': s:lisp_style,
  \ }

if exists('g:fileheader_delimiter_map')
  call extend(s:delimiter_map, g:fileheader_delimiter_map)
endif

if g:fileheader_by_git_config == 1
  let s:author = get(systemlist('git config user.name'), 0)
  if !empty(s:author)
    let g:fileheader_author = s:author
  endif

  if g:fileheader_show_email
    let s:email = get(systemlist('git config user.email'), 0)
    if !empty(s:email)
      let g:fileheader_email = s:email
    endif
  endif
endif

let s:creator_templates = [
  \ '@Author: {{author}} <{{email}}>',
  \ '@Date: {{date}}',
  \ ]

let s:editor_templates = [
  \ '@Last Modified by: {{author}} <{{email}}>',
  \ '@Last Modified time: {{date}}',
  \ ]

let s:templates = s:creator_templates + s:editor_templates

function! fileheader#render_template(tpl)
  let line = a:tpl
  let line = substitute(line, '{{author}}', g:fileheader_author, 'g')
  let line = substitute(line, '{{email}}', g:fileheader_email, 'g')
  let line = substitute(line, '{{Date}}', strftime("%Y-%m-%d %H:%M:%S"), 'g')
  return line
endfunction

function! fileheader#get_header(delimiter)
  let begin_line = a:delimiter['begin']
  let end_line = a:delimiter['end']
  let char = a:delimiter['char']

  let header = []
  for tpl in s:templates
    let line = fileheader#render_template(tpl)
    call add(header, char.line)
  endfor
  if !empty(begin_line)
    call insert(header, begin_line, 0)
  endif
  if !empty(end_line)
    call add(header, end_line)
  endif
  if g:fileheader_new_line_at_end
    call add(header, '')
  endif

  return header
endfunction

function! fileheader#add_file_header()
  let delimiter = get(s:delimiter_map, &filetype)

  if !empty(delimiter)
    let header = fileheader#get_header(delimiter)
    for line in reverse(header)
      call append(0, line)
    endfor
  else
    echo 'vim-fileheader: can not found '.&filetype.' filetype delimiter'
  endif
endfunction

function! fileheader#update_file_header()
  let delimiter = get(s:delimiter_map, &filetype)

  if !empty(delimiter)
    let cursor = getpos(".")
    for tpl in s:editor_templates
      let pat = substitute(tpl, '{{.*}}', '.*', 'g')
      let sub = fileheader#render_template(tpl)
      silent! execute ':1,10s/'.pat.'/'.sub.'/g'
    endfor
    call setpos('.', cursor)
  endif
endfunction

command! -range=% AddFileHeader call fileheader#add_file_header()
command! -range=% UpdateFileHeader call fileheader#update_file_header()

if g:fileheader_auto_add
  autocmd BufRead * call fileheader#add_file_header()
endif

if g:fileheader_auto_update
  autocmd BufWritePre * call fileheader#update_file_header()
endif
