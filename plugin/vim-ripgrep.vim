if exists('g:loaded_rg') || &cp
  finish
endif

let g:loaded_rg = 1

if !exists('g:rg_binary')
  let g:rg_binary = 'rg'
endif

if !exists('g:rg_format')
  let g:rg_format = "%f:%l:%c:%m"
endif

if !exists('g:rg_command')
  let g:rg_command = g:rg_binary . ' --vimgrep'
endif

if !exists('g:rg_root_types')
  let g:rg_root_types = ['.git']
endif

if !exists('g:rg_window_location')
  let g:rg_window_location = 'botright'
endif

fun! g:RipGrepVisual() range
  call s:RipGrepGrepContext(function('s:RipGrepSearch'), '"' . s:RipGrepGetVisualSelection() . '"')
endfun

fun! s:RipGrep(txt)
  call s:RipGrepGrepContext(function('s:RipGrepSearch'), s:RipGrepSearchTerm(a:txt))
endfun

fun! s:RipGrepGetVisualSelection()
    " Why is this not a built-in Vim script function?!
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfun

fun! s:RipGrepSearchTerm(txt)
  if empty(a:txt)
    return expand("<cword>")
  else
    return a:txt
  endif
endfun

fun! s:RipGrepSearch(txt)
  let l:rgopts = ' '
  if &ignorecase == 1
    let l:rgopts = l:rgopts . '-i '
  endif
  if &smartcase == 1
    let l:rgopts = l:rgopts . '-S '
  endif
  silent! exe 'grep! ' . l:rgopts . a:txt
  if len(getqflist())
    exe g:rg_window_location 'copen'
    redraw!
    if exists('g:rg_highlight')
      call s:RipGrepHighlight(a:txt)
    endif
  else
    cclose
    redraw!
    echo "No match found for " . a:txt
  endif
endfun

fun! s:RipGrepGrepContext(search, txt)
  let l:grepprgb = &grepprg
  let l:grepformatb = &grepformat
  let &grepprg = g:rg_command
  let &grepformat = g:rg_format
  let l:te = &t_te
  let l:ti = &t_ti
  let l:shellpipe_bak=&shellpipe
  set t_te=
  set t_ti=
  if !has("win32")
    let &shellpipe="&>"
  endif

  if exists('g:rg_derive_root')
    call s:RipGrepPathContext(a:search, a:txt)
  else
    call a:search(a:txt)
  endif

  let &shellpipe=l:shellpipe_bak
  let &t_te=l:te
  let &t_ti=l:ti
  let &grepprg = l:grepprgb
  let &grepformat = l:grepformatb
endfun

fun! s:RipGrepPathContext(search, txt)
  let l:cwdb = getcwd()
  exe 'lcd '.s:RipGrepRootDir()
  call a:search(a:txt)
  exe 'lcd '.l:cwdb
endfun

fun! s:RipGrepHighlight(txt)
  let @/=escape(substitute(a:txt, '"', '', 'g'), '|')
  call feedkeys(":let &hlsearch=1\<CR>", 'n')
endfun

fun! s:RipGrepRootDir()
  let l:cwd = getcwd()
  let l:dirs = split(getcwd(), '/')

  for l:dir in reverse(copy(l:dirs))
    for l:type in g:rg_root_types
      let l:path = s:RipGrepMakePath(l:dirs, l:dir)
      if s:RipGrepHasFile(l:path.'/'.l:type)
        return l:path
      endif
    endfor
  endfor
  return l:cwd
endfun

fun! s:RipGrepMakePath(dirs, dir)
  return '/'.join(a:dirs[0:index(a:dirs, a:dir)], '/')
endfun

fun! s:RipGrepHasFile(path)
  return filereadable(a:path) || isdirectory(a:path)
endfun

fun! s:RipGrepShowRoot()
  if exists('g:rg_derive_root')
    echo s:RipGrepRootDir()
  else
    echo getcwd()
  endif
endfun

command! -nargs=* -complete=file RipGrep :call s:RipGrep(<q-args>)
command! RipGrepRoot :call s:RipGrepShowRoot()
