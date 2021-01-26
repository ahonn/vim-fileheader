" @Author: ahonn
" @Date: 2018-10-03 23:38:15
" @Last Modified by: ahonn
" @Last Modified time: 2021-01-26 23:34:41

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
  \ 'vue': s:html_style,
  \ 'erlang': s:erlang_style,
  \ 'clojure': s:lisp_style,
  \ 'scheme': s:lisp_style,
  \ }

if exists('g:fileheader_delimiter_map')
  call extend(s:delimiter_map, g:fileheader_delimiter_map)
endif

let s:templates = [
  \ '@Author: {{author}} <{{email}}>',
  \ '@Date: {{created_date}}',
  \ '@Last Modified by: {{modifier}} <{{modifier_email}}>',
  \ '@Last Modified time: {{modified_date}}',
  \ ]

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

" load git config user name and email
function! fileheader#load_git_config()
  let s:job_ids = []
  if has('nvim')
    function! s:set_author_handler(id, data, event)
      let msg = join(a:data, '')
      if msg != ''
        let g:fileheader_author = msg
      endif
    endfunction
  else
    function! s:set_author_handler(channel)
      while ch_status(a:channel, {'part': 'out'}) == 'buffered'
        let msg = ch_read(a:channel)
        if msg != ''
          let g:fileheader_author = msg
        endif
      endwhile
    endfunction
  endif
  call fileheader#run_command_async(['git', 'config', '--get', 'user.name'], function('s:set_author_handler'))

  if g:fileheader_show_email
    if has('nvim')
      function! s:set_email_handler(id, data, event)
        let msg = join(a:data, '')
        if msg != ''
          let g:fileheader_email = msg
        endif
      endfunction
    else
      function! s:set_email_handler(channel)
        while ch_status(a:channel, {'part': 'out'}) == 'buffered'
          let msg = ch_read(a:channel)
          if msg != ''
            let g:fileheader_email = msg
          endif
        endwhile
      endfunction
    endif
    call fileheader#run_command_async(['git', 'config', '--get', 'user.email'], function('s:set_email_handler'))
  endif
endfunction

" get current file name
function! fileheader#get_file_name()
  let ext = tolower(expand("%:e"))
  let fname = tolower(expand('%<'))
  let filename = fname.'.'.ext
  return filename
endfunction

" check whether the file has been modified
function! fileheader#file_not_modifyed()
  let filename = fileheader#get_file_name()

  if !filereadable(filename)
    return 0
  endif

  let file_content = readfile(filename)
  let buffer_content = getline(1, '$')
  return buffer_content == file_content
endfunction

" render template by author/email/date and update modifier information when modified
function! fileheader#render_template(tpl, update)
  let tpl = a:tpl
  let date = strftime(g:fileheader_date_format)

  " skip when update, just render at first time
  if !a:update
    if match(tpl, '{{author}}') != -1
      let tpl = substitute(tpl, '{{author}}', g:fileheader_author, 'g')
    end

    if match(tpl, '{{email}}') != -1
      if g:fileheader_show_email
        let tpl = substitute(tpl, '{{email}}', g:fileheader_email, 'g')
      else
        let tpl = substitute(tpl, '{{email}}', '', 'g')
      endif
    end

    if match(tpl, '{{created_date}}') != -1
      let tpl = substitute(tpl, '{{created_date}}', date, 'g')
    end
  end

  if match(tpl, '{{modifier}}') != -1
    let tpl = substitute(tpl, '{{modifier}}', g:fileheader_author, 'g')
  end

  if match(tpl, '{{modifier_email}}') != -1
    if g:fileheader_show_email
      let tpl = substitute(tpl, '{{modifier_email}}', g:fileheader_email, 'g')
    else
      let tpl = substitute(tpl, '{{modifier_email}}', '', 'g')
    endif
  end

  if match(tpl, '{{modified_date}}') != -1
    let not_modifyed = fileheader#file_not_modifyed()
    if (a:update)
      if not_modifyed
        let date_line_pat = substitute(tpl, '{{modified_date}}', '.*', 'g')
        let date_line_number = search(date_line_pat)
        let tpl = matchstr(getline(date_line_number), date_line_pat)
      end
    endif

    let tpl = substitute(tpl, '{{modified_date}}', date, 'g')
  end

  call histdel('search', -1)
  return tpl
endfunction

" get file header templates, supported custom
function! fileheader#get_templates()
  let templates = get(g:fileheader_templates_map, &filetype)
  if empty(templates)
    let templates = s:templates
  endif
  return templates
endfunction

function! fileheader#get_header(delimiter)
  let begin_line = a:delimiter['begin']
  let end_line = a:delimiter['end']
  let char = a:delimiter['char']

  let header = []
  " add begin line
  if !empty(begin_line)
    let lines = split(begin_line, "\n")
    for line in lines
      call add(header, line)
    endfor
  endif

  " render by template
  let templates = fileheader#get_templates()
  for tpl in templates
    let line = fileheader#render_template(tpl, 0)
    call add(header, char.line)
  endfor

  " add end line
  if !empty(end_line)
    let lines = split(end_line, "\n")
    for line in lines
      call add(header, line)
    endfor
  endif
  if g:fileheader_new_line_at_end
    call add(header, '')
  endif

  return header
endfunction

function! fileheader#add_file_header()
  let delimiter = get(s:delimiter_map, &filetype)

  if !empty(delimiter)
    if g:fileheader_author == ''
      echo 'vim-fileheader: can not found g:fileheader_author value'
      return
    endif

    let header = fileheader#get_header(delimiter)
    call append(0, header)
  else
    echo 'vim-fileheader: can not found '.&filetype.' filetype delimiter'
  endif
endfunction

function! fileheader#auto_add_file_header()
  let content = join(getline(0, '$'), '')
  if content == ''
    call fileheader#add_file_header()
  endif
endfunction

function! fileheader#update_file_header()
  let delimiter = get(s:delimiter_map, &filetype)

  if !empty(delimiter)
    let cursor = getpos(".")

    let templates = fileheader#get_templates()
    for tpl in templates
      let match_modifier = match(tpl, '{{modifier}}') != -1
      let match_modifier_email = match(tpl, '{{modifier_email}}') != -1
      let match_modified_date = match(tpl, '{{modified_date}}') != -1
      if match_modifier || match_modifier_email || match_modified_date
        let pat = substitute(tpl, '{{.*}}', '.*', 'g')
        let sub = fileheader#render_template(tpl, 1)

        let max_line_number = line('$')
        let last_line_number = 10
        if (max_line_number < 10)
          let last_line_number = max_line_number
        endif
        silent! execute ':undojoin | 1,'.last_line_number.'s/'.pat.'/'.sub.'/g'
      end
    endfor

    call histdel('search', -1)
    call setpos('.', cursor)

  endif
endfunction
