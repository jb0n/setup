" turn on the syntax checker
syntax on

" don't check syntax immediately on open or on quit
let g:ale_lint_on_enter = 0
let g:ale_lint_on_save = 1


" i dunno if I really want this. maybe
let g:ale_go_golangci_lint_package = 1

" error symbol to use in sidebar
"let g:ale_sign_error = '☢️'
"let g:ale_sign_warning = '⚡'
"☢️ ⚡ ❯ ❱🮥'
let g:ale_sign_error = '❱'
let g:ale_sign_warning = '❱'


" show number of errors
function! LinterStatus() abort
    let l:counts = ale#statusline#Count(bufnr(''))
    let l:all_errors = l:counts.error + l:counts.style_error
    let l:all_non_errors = l:counts.total - l:all_errors
    return l:counts.total == 0 ? 'OK' : printf(
        \   '%d⨉ %d⚠ ',
        \   all_non_errors,
        \   all_errors
        \)
endfunction
set statusline+=%=
set statusline+=\ %{LinterStatus()}

" format error strings
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'


let g:ale_linters = {'go': ['gometalinter', 'gofmt', 'govet', 'gofumpt', 'golangci-lint']}

