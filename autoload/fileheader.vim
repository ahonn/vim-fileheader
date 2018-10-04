" @Author: ahonn <ahonn95@outlook.com>
" @Date: 2018-10-03 23:38:15
" @Last Modified by: ahonn <ahonn95@outlook.com>
" @Last Modified time: 2018-10-04 21:27:07

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

let s:creator_templates = [
  \ '@Author: {{author}} <{{email}}>',
  \ '@Date: {{date}}',
  \ ]

let s:editor_templates = [
  \ '@Last Modified by: {{author}} <{{email}}>',
  \ '@Last Modified time: {{date}}',
  \ ]

let s:templates = s:creator_templates + s:editor_templates

function! fileheader#run_command_async(cmd, handler)
  if has('nvim')
    call jobstart(a:cmd, { 'on_stdout': a:handler })
  else
    if has('job')
      call job_start(a:cmd, { 'close_cb': a:handler })
    else
      throw 'vim-fileheader: please use vim 8.0 or above'
    endif
  endif
endfunction

function! fileheader#load_git_config()
  if has('nvim')
    function! s:set_author_handler(id, data, evnet)
      let msg = join(a:data, '')
      let g:fileheader_author = msg
    endfunction
  else
    function! s:set_author_handler(channel)
      while ch_status(a:channel, {'part': 'out'}) == 'buffered'
        let msg = ch_read(a:channel)
        let g:fileheader_author = msg
      endwhile
    endfunction
  endif
  call fileheader#run_command_async('git config user.name', function('s:set_author_handler'))

  if g:fileheader_show_email
    if has('nvim')
      function! s:set_email_handler(id, data, event)
        let msg = join(a:data, '')
        let g:fileheader_email = msg
      endfunction
    else
      function! s:set_email_handler(channel)
        while ch_status(a:channel, {'part': 'out'}) == 'buffered'
          let msg = ch_read(a:channel)
          let g:fileheader_email = msg
        endwhile
      endfunction
    endif
    call fileheader#run_command_async('git config user.email', function('s:set_email_handler'))
  endif
endfunction

function! fileheader#get_file_name()
  let ext = tolower(expand("%:e"))
  let fname = tolower(expand('%<'))
  let filename = fname.'.'.ext
  return filename
endfunction

function! fileheader#file_not_modifyed()
  let filename = fileheader#get_file_name()
  let file_content = readfile(filename)
  let buffer_content = getline(1, '$')

  let not_modifyed = buffer_content == file_content
  return not_modifyed
endfunction

function! fileheader#render_template(tpl, update)
  let line = a:tpl
  if match(line, '{{author}}') != -1
    let line = substitute(line, '{{author}}', g:fileheader_author, 'g')
  end

  if match(line, '{{email}}') != -1
    let line = substitute(line, '{{email}}', g:fileheader_email, 'g')
  end

  if match(line, '{{date}}') != -1
    let date = strftime("%Y-%m-%d %H:%M:%S")
    if (a:update)
      let not_modifyed = fileheader#file_not_modifyed()
      if not_modifyed
        let date_line_pat = substitute(line, '{{date}}', '.*', 'g')
        let date_line_number = search(date_line_pat)
        let line = matchstr(getline(date_line_number), date_line_pat)
      end
    end

    let line = substitute(line, '{{date}}', date, 'g')
  end
  return line
endfunction

function! fileheader#get_header(delimiter)
  let begin_line = a:delimiter['begin']
  let end_line = a:delimiter['end']
  let char = a:delimiter['char']

  let header = []
  for tpl in s:templates
    let line = fileheader#render_template(tpl, 0)
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
      let sub = fileheader#render_template(tpl, 1)

      let max_line_number = line('$')
      let last_line_number = 10
      if (max_line_number < 10)
        let last_line_number = max_line_number
      endif
      silent! execute ':1,'.last_line_number.'s/'.pat.'/'.sub.'/g'
    endfor
    call setpos('.', cursor)
  endif
endfunction
