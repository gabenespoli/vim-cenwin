" cenwin v2

function! CenWinToggle()
    " check state of cenwin and call either enable or disable
    " check state of sidebars and reenable after if needed
    " maybe need to remove them first
endfunc

function CenWinOutlineToggle()
    " check state of cenwin and adjust width accordingly
    " if cenwin, width is based on the width of the cenwin
    " if no cenwin, width is based on global setting (default 1/4 of window)
endfunc

function CenWinTodoToggle()
    " same as outline
endfunc

function CenWinOutlineTypeToggle()
    " switch between function or double comment char outline
endfunc

function! CenWinEnable()
    " check if we are in a location list or quickfix window
    " if so, open the buffer in the cenwinbuf variable
    " make this the only window visible, then center it
endfunc
