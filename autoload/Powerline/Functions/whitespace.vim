
" MIT License. Copyright (c) 2013-2016 Bailey Ling.
" vim: et ts=2 sts=2 sw=2

" http://got-ravings.blogspot.com/2008/10/vim-pr0n-statusline-whitespace-flags.html

scriptencoding utf-8

let s:show_message = 1
let s:default_checks = ['indent', 'trailing', 'mixed-indent-file']

let s:trailing_format = '[%s]trailing'
let s:mixed_indent_format = '[%s]mixed-indent'
let s:long_format =  '[%s]long'
let s:mixed_indent_file_format =  '[%s]mix-indent-file'
let s:indent_algo = 0
let s:skip_check_ft = {'make': ['indent', 'mixed-indent-file'] }
let s:max_lines = 20000
let s:enabled = 1
let s:c_like_langs = get(g:, 'airline#extensions#c_like_langs', [ 'c', 'cpp', 'cuda', 'go', 'javascript', 'ld', 'php' ])
let s:symbol = '☲'

function! s:check_mixed_indent()
  if s:indent_algo == 1
    " [<tab>]<space><tab>
    " spaces before or between tabs are not allowed
    let t_s_t = '(^\t* +\t\s*\S)'
    " <tab>(<space> x count)
    " count of spaces at the end of tabs should be less than tabstop value
    let t_l_s = '(^\t+ {' . &ts . ',}' . '\S)'
    return search('\v' . t_s_t . '|' . t_l_s, 'nw')
  elseif s:indent_algo == 2
    return search('\v(^\t* +\t\s*\S)', 'nw')
  else
    return search('\v(^\t+ +)|(^ +\t+)', 'nw')
  endif
endfunction

function! s:check_mixed_indent_file()
  if index(s:c_like_langs, &ft) > -1
    " for C-like languages: allow /** */ comment style with one space before the '*'
    let head_spc = '\v(^ +\*@!)'
  else
    let head_spc = '\v(^ +)'
  endif
  let indent_tabs = search('\v(^\t+)', 'nw')
  let indent_spc  = search(head_spc, 'nw')
  if indent_tabs > 0 && indent_spc > 0
    return printf("%d:%d", indent_tabs, indent_spc)
  else
    return ''
  endif
endfunction

function! s:shorten(text, winwidth, minwidth)
  if winwidth(0) < a:winwidth && len(split(a:text, '\zs')) > a:minwidth
    return matchstr(a:text, '^.\{'.a:minwidth.'}').'…'
  else
    return a:text
  endif
endfunction
function! Powerline#Functions#whitespace#Check()
  if &readonly || !&modifiable || !s:enabled || line('$') > s:max_lines
          \ || get(b:, 'whitespace_disabled', 0)
    return ''
  endif
  if !exists('b:whitespace_check')
    let b:whitespace_check = ''
    let checks = s:default_checks

    let trailing = 0
    if index(checks, 'trailing') > -1
      try
        let regexp = '\s$'
        let trailing = search(regexp, 'nw')
      catch
        echomsg 'whitespace: error occured evaluating '. regexp
        echomsg v:exception
        return ''
      endtry
    endif

    let mixed = 0
    let check = 'indent'
    if index(checks, check) > -1 && index(get(s:skip_check_ft, &ft, []), check) < 0
      let mixed = s:check_mixed_indent()
    endif

    let mixed_file = ''
    let check = 'mixed-indent-file'
    if index(checks, check) > -1 && index(get(s:skip_check_ft, &ft, []), check) < 0
      let mixed_file = s:check_mixed_indent_file()
    endif

    let long = 0
    if index(checks, 'long') > -1 && &tw > 0
      let long = search('\%>'.&tw.'v.\+', 'nw')
    endif

    if trailing != 0 || mixed != 0 || long != 0 || !empty(mixed_file)
      let b:whitespace_check = s:symbol
      if strlen(s:symbol) > 0
        let space = ' '
      else
        let space = ''
      endif

      if s:show_message
        if trailing != 0
          let b:whitespace_check .= space.printf(s:trailing_format, trailing)
        endif
        if mixed != 0
          let b:whitespace_check .= space.printf(s:mixed_indent_format, mixed)
        endif
        if long != 0
          let b:whitespace_check .= space.printf(s:long_format, long)
        endif
        if !empty(mixed_file)
          let b:whitespace_check .= space.printf(s:mixed_indent_file_format, mixed_file)
        endif
      endif
    endif
  endif
  return s:shorten(b:whitespace_check, 120, 9)
endfunction
augroup whitespace
  autocmd!
  autocmd CursorHold,BufWritePost * if exists('b:whitespace_check') | unlet b:whitespace_check | endif
augroup END
