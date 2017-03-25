" cenwin
"
" Vim plugin to center the current window by adding a vertical split on either
" side. Can then display the location list (with functions or headings) and 
" quickfix window (with todos present throughout the file) in those panes.
"
" center the pane by creating two empty panes on either side
" first arg is width of centered window (default 80)
" second arg is the width of the left-hand pad 
"   (default (winwidth - centerwidth) / 2)

"TODO make g:CenWinOutlineExpr and g:CenWinTodoExpr globals so that todo add/remove can use them
"TODO make secondary location list for double comment characters, maybe map to
"<localleader>L
"TODO don't throw an error if there aren't any todos or outlined things
"TODO refresh lists; have a g:var for status of toc/todo
"TODO add var to choose side of screen that the list shows on
"TODO let user set filetype-specific regexes to search for
"TODO search loc list for line numbers before formatting it to jump the cursor
"to the corresponding line. i hate when it always starts at the top
"TODO keep sidebars updated as the cenwin buffer changes

" defaults
let g:CenWinStatus = 0 " buffer number of the centered window
let g:CenWinLeftPad = 0 " buffer number of pad so it can be reused
let g:CenWinRightPad = 0
let g:CenWinWidth = 100
let g:CenWinLeftWidth = 0
let g:CenWinRightWidth = 0
let g:CenWinOutline = 0 " boolean
let g:CenWinOutlineType = 1 " 1 = functions; 2 = double comment char
let g:CenWinTodo = 0 " boolean
let g:CenWinFiletype = ""

function! CenWinToggle(...)
    if a:0 == 0
        let opt = 0
    else
        let opt = a:1
    endif
    if g:CenWinStatus == 0
        call CenWinEnable(opt)
    else
        call CenWinDisable(opt)
    endif
endfunc

function! CenWinToggleWidth()
    if g:CenWinWidth == 100
        let g:CenWinWidth = 80
    else
        let g:CenWinWidth = 100
    endif
endfunc

function! CenWinOutlineToggle(...)
    " input: (width,state)
    " state: 0 = off; 1 = functions; 2 = double comment char
    if a:0 == 0 " no input, toggle
        if g:CenWinOutline == 0
            call call("CenWinOutlineEnable", a:000)
        else
            call CenWinOutlineDisable()
        endif
    elseif a:0 > 1 " input given, force given state
        if g:CenWinOutline == a:2
            call CenWinOutlineDisable()
        else 
            call call("CenWinOutlineEnable", a:000)
        endif
    else 
        echohl Search
        echo "cenwin.vim: Incorrect input to CenWinOutlineToggle()."
        echohl None
    endif
endfunc

function! CenWinTodoToggle(...)
    if a:0 == 0 " no input, toggle
        if g:CenWinTodo == 0
            call CenWinTodoEnable()
        else
            call CenWinTodoDisable()
        endif
    elseif a:1 == 0 " input given, force given state
        if g:CenWinTodo != 0
            call CenWinTodoDisable()
        endif
    else " a:1 != 0
        if g:CenWinTodo == 0
            call CenWinTodoEnable()
        endif
    endif
endfunc

function! CenWinEnable(...)
    if a:0 == 0
        if g:CenWinWidth == 0
            let g:CenWinWidth = 80
        endif
    else
        if a:1 != 0
            let g:CenWinWidth = a:1
            let g:CenWinLeftWidth = (winwidth('%') - g:CenWinWidth) / 2
        endif
    endif
    "TODO round leftpadwidth to avoid decimals
    if g:CenWinLeftWidth == 0
        let g:CenWinLeftWidth = (winwidth('%') - g:CenWinWidth) / 2
    endif

    exe "normal! \<C-w>o"
    let currentsplitrightvalue = &splitright

    " add left side pad pane and move focus back to center
    set nosplitright
    if g:CenWinLeftPad == 0
        vnew
        let g:CenWinLeftPad = bufnr('%') 
        set nobuflisted
        setlocal nonumber
        setlocal statusline=%(%)
        set nocursorline
    else
        vsplit
        exe "buffer".g:CenWinLeftPad
    endif
    exe "vertical resize ".g:CenWinLeftWidth
    exe "normal! \<C-w>l"

    " add right side pad pane and move focus back to center
    set splitright
    if g:CenWinRightPad == 0
        vnew
        let g:CenWinRightPad = bufnr('%')
        set nobuflisted
        setlocal nonumber
        setlocal statusline=%(%)
        set nocursorline
    else
        vsplit
        exe "buffer".g:CenWinRightPad
    endif
    exe "normal! \<C-w>h"

    " resize center window, get right pad width
    exe "vert resize ".g:CenWinWidth
    let g:CenWinStatus = bufnr('%')
    exe "normal! \<C-w>l"
    let g:CenWinRightWidth = winwidth('%')
    exe "normal! \<C-w>h"

    " reset splitright value
    let &splitright=currentsplitrightvalue
endfunc

function! CenWinOutlineEnable(...)
    " first input arg (width of window)
    if (a:0 == 0) || (a:1 == 0) " default or already-set width
        if g:CenWinLeftWidth != 0
            let l:tocWidth = g:CenWinLeftWidth
        else
            let l:tocWidth = winwidth('%') / 4
        endif
    else " do specified width
        let l:tocWidth = a:1
    endif

    " second input arg (search expr for creating outline)
    let g:CenWinFiletype = &filetype
    if (a:0 == 0) || (a:2 != 2) " default search expr (functions)
        if g:CenWinFiletype == 'markdown' || g:CenWinFiletype == 'pandoc'
            let g:CenWinOutlineExpr = '^#'
        elseif g:CenWinFiletype == 'vim'
            let g:CenWinOutlineExpr = '^function! '
        elseif g:CenWinFiletype == 'matlab'
            let g:CenWinOutlineExpr = '^function '
        endif
        let g:CenWinOutline = 1
    else " double comment mark search expr
        if g:CenWinFiletype == 'markdown' || g:CenWinFiletype == 'pandoc'
            let g:CenWinOutlineExpr = '^#'
        elseif g:CenWinFiletype == 'vim'
            let g:CenWinOutlineExpr = '^""'
        elseif g:CenWinFiletype == 'matlab'
            let g:CenWinOutlineExpr = '^%%'
        else
            let g:CenWinOutlineExpr = '^##'
        endif
        let g:CenWinOutline = 2
    endif

"    if a:0 != 0
"        let l:tocWidth = a:1
"    elseif g:CenWinLeftWidth != 0
"        let l:tocWidth = g:CenWinLeftWidth
"    else
"        let l:tocWidth = winwidth('%') / 4
"    endif

    " close left pad to make room for toc
    if g:CenWinStatus != 0
        exe "normal! \<C-w>h\<C-w>h"
        close
    endif

    " create the location list, open it, format it
    " inspired by vim-pandoc/autoload/toc.vim
    try
        execute 'silent lvimgrep /' . g:CenWinOutlineExpr . '/ %'
    catch
        echohl Search
        echo "cenwin.vim: Outline expr not found in file."
        echohl None
        return
    endtry
    execute "topleft vertical lopen"
    execute "vertical resize " . l:tocWidth
    set modifiable
    silent %s/\v^([^|]*\|){2,2} //e
    if g:CenWinFiletype == 'markdown' || g:CenWinFiletype == 'pandoc'
        silent %s/#\ //g
        silent %s/#/\ \ /g
        syn match CenWinOutlineHeader1 /^\S.*\n/
        syn match CenWinOutlineHeader2 /^\s\s\S.*\n/
        syn match CenWinOutlineHeader3 /^\s\s\s\s\S.*\n/
        syn match CenWinOutlineHeader4 /^\s\s\s\s\s\s\S.*\n/
        syn match CenWinOutlineHeader5 /^\s\s\s\s\s\s\s\s\S.*\n/
        syn match CenWinOutlineHeader6 /^\s\s\s\s\s\s\s\s\s\s\S.*\n/
    else
        execute 'silent %s/' . g:CenWinOutlineExpr . '//g'
        syn match CenWinOutline /.*/
        hi link CenWinOutline Normal
    endif
    set nomodified
    set nomodifiable
    set cursorline
    setlocal nowrap
    normal! gg

    " set some keybindings
    nnoremap <buffer> q     :call CenWinOutlineDisable()<CR>
    nnoremap <buffer> l     :call CenWinOutlineDisable()<CR>
    nnoremap <buffer> <localleader>l     :call CenWinOutlineDisable()<CR>
    nnoremap <buffer> O     <CR>zt:call CenWinOutlineDisable()<CR>
    nnoremap <buffer> <CR>  <CR>zt
    nnoremap <buffer> <C-j> <CR>zt
    nnoremap <buffer> o     <CR>zt<C-w>h
    nnoremap <buffer> <leader><leader> <CR>zt<C-w>h
    nnoremap <buffer> J 5j
    nnoremap <buffer> K 5k
    nnoremap <buffer> <C-n> <Down><CR>zt<C-w>h
    nnoremap <buffer> <C-p> <Up><CR>zt<C-w>h


    " resize center window if needed
    if g:CenWinStatus != 0
        exe "normal! \<C-w>l"
        exe "vertical resize " . g:CenWinWidth
        exe "normal! \<C-w>h"
    endif

endfunc

function! CenWinTodoEnable(...)
    if a:0 != 0
        let l:tocWidth = a:1
    elseif g:CenWinRightWidth != 0
        let l:tocWidth = g:CenWinRightWidth
    else
        let l:tocWidth = winwidth('%') / 4
    endif

    " close right pad to make room for toc
    if g:CenWinStatus != 0
        exe "normal! \<C-w>l\<C-w>l"
        close
    endif

    " create the quickfix list, open it, format it
    let g:CenWinFiletype = &filetype
    "let g:CenWinCommentChar = ''
    if g:CenWinFiletype == 'markdown' || g:CenWinFiletype == 'pandoc'
        let g:CenWinTodoExpr = '^\s*TODO'
        "let g:CenWinCommentChar = ''
    elseif g:CenWinFiletype == 'vim'
        let g:CenWinTodoExpr = '^\s*"\s*TODO'
        "let g:CenWinCommentChar = '"'
    elseif g:CenWinFiletype == 'matlab'
        let g:CenWinTodoExpr = '^\s*%\s*TODO'
        "let g:CenWinCommentChar = '%'
    else
        "g:CenWinTodoExpr = '^\s*#\s*TODO'
        let g:CenWinCommentChar = '#'
    endif
    try
        "if g:CenWinCommentChar == ''
        execute 'silent vimgrep /' . g:CenWinTodoExpr . '/ %'
        "else
        "    execute 'silent vimgrep /\s*' . g:CenWinCommentChar . '\s*TODO'
        "endif 
        execute "vertical copen"
        execute "vertical resize " . l:tocWidth
        set modifiable
        silent %s/\v^([^|]*\|){2,2} //e
        execute 'silent %s/' . g:CenWinTodoExpr . '//g'
        silent %s/^\s//g
        syn match CenWinTodo /.*/
        hi link CenWinTodo Normal
        set filetype=todo
        set nomodified
        set nomodifiable
        set cursorline " highlight line with cursor
        set number
        normal! gg
        nnoremap <buffer> q     :call CenWinTodoDisable()<CR>
        nnoremap <buffer> O     <CR>zt:call CenWinTodoDisable()<CR>
        nnoremap <buffer> <C-j> <CR>zt
        nnoremap <buffer> o     <CR>zt<C-w>l
        nnoremap <buffer> <leader><leader> <CR>zt<C-w>l
        nnoremap <buffer> J 5j
        nnoremap <buffer> K 5k
        nnoremap <buffer> j j
        nnoremap <buffer> k k
        nnoremap <buffer> <C-n> <Down><CR>zt<C-w>l
        nnoremap <buffer> <C-p> <Up><CR>zt<C-w>l

        " these require that the todo-txt.vim plugin is installed
        " specifically, the functions used in CenWinTodoPriority()
        nnoremap <buffer> <localleader>a :call CenWinTodoPriority('A')<CR>
        nnoremap <buffer> <localleader>b :call CenWinTodoPriority('B')<CR>
        nnoremap <buffer> <localleader>c :call CenWinTodoPriority('C')<CR>
        nnoremap <buffer> <localleader>0 :call CenWinTodoPriority()<CR>
        "nnoremap <buffer> <localleader>j <CR>:call CenWinTodoPriority('+')<CR>:call CenWinTodoEnable<CR>
        "nnoremap <buffer> <localleader>k <CR>:call CenWinTodoPriority('-')<CR>:call CenWinTodoEnable<CR>

        " resize splits if needed
        if g:CenWinStatus != 0
            exe "normal! \<C-w>h\<C-w>h"
            exe "vertical resize " . g:CenWinLeftWidth
            exe "normal! \<C-w>l"
            exe "vertical resize " . g:CenWinWidth
            exe "normal! \<C-w>l"
        endif

        let g:CenWinTodo = 1
    catch
        echo 'No todos found in file'
    endtry
endfunc

function! CenWinTodoPriority(...)
    "this function requires that todo-txt.vim plugin is installed
    "this function is meant to be called when focus is in the todo list
    let oldpos=getcurpos()
    .cc
    if a:0 == 0 " remove priority j
        call CenWinTodoRemove()
        call todo#RemovePriority()
        call CenWinTodoAdd()
    "elseif a:1 == '+'
    "    call CenWinTodoRemove()
    "    call todo#PrioritizeIncrease()
    "    call CenWinTodoAdd()
    "elseif a:1 == '-'
    "    call CenWinTodoRemove()
    "    call todo#PrioritizeDecrease()
    "    call CenWinTodoAdd()
    else
        call CenWinTodoRemove()
        call todo#PrioritizeAdd(a:1)
        call CenWinTodoAdd()
    endif
    call CenWinTodoEnable()
    call setpos('.',oldpos)
endfunc

function! CenWinTodoRemove()
    :s/^TODO\ //ge
endfunc

function! CenWinTodoAdd()
    "exe 'normal! 0iTODO '
    exe 'normal! 0i' . g:CenWinTodoExpr
endfunc

function! CenWinDisable(...)
    " enter 0 to disable if g:CenWinStatus is non-zero
    " enter 1 to force disable it
    let do=0
    if a:0 > 0 && a:1 != 0
        let do = 1
    endif
    if g:CenWinStatus != 0
        let do = 1
    endif

    " get current buffer (the one in the cenwin)
    " save current switchbuf setting and add useopen to it
    " switch to left and right pads and close them
    " switch back to cenwinstatus


    if do == 1
        exe "buffer".g:CenWinStatus
        exe "normal! \<C-w>o"
        let g:CenWinStatus = 0
    endif
endfunc

function! CenWinOutlineDisable()
    exe "normal! \<C-w>h\<C-w>h"
    if g:CenWinStatus == 0
        exe "close"
    else
        exe "buffer".g:CenWinLeftPad
        exe "normal! \<C-w>l"
    endif
    let g:CenWinOutline = 0
endfunc

function! CenWinTodoDisable()
    if g:CenWinStatus == 0
        cclose
    else
        exe "normal! \<C-w>l\<C-w>l"
        exe "buffer".g:CenWinRightPad
        exe "normal! \<C-w>h"
    endif
    let g:CenWinTodo = 0
endfunc
