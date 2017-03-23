# vim-cenwin: Centered Window

This is a vim plugin to center the current file in the terminal window by adding a blank pane on either side. These panes can then be populated with a document outline (using markdown headings, function headings, or lines with a double comment character (e.g., ##, %%, or "")) or todos placed throughout the file (e.g., TODO, #TODO, # TODO, etc.). These functions use the location list and quickfix window, respectively. This is my first vim plugin and is still very much in development.

cenwin.vim is a first pass at this function and works ok.
cenwin2.vim is under development as a complete rewrite.

## keybindings

The default keybindings are meant to work in tandem with [vim-unimpaired](https://github.com/tpope/vim-unimpaired).

`<leader>c` center the window with the default width of 80 characters
`<localleader>l` open the location list with an outline (functions)
`<localleader>L` open the location list with an outline (double comment characters; will be deprecated in favour of a buffer-local switch between the two types of lists)
`<localleader>q` open the todos as a quickfix window

## todos

The todo list quickfix window will have the filetype 'todo'. This means that if the [todo-txt.vim](https://github.com/vim-scripts/todo-txt.vim) plugin is installed, then the todo list will have the same syntax highlighting and some of the same keyboard shortcuts for managing priorities.

