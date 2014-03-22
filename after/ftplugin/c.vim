func! FindFileWithContentsUp(path, fname, keyword)
python << EOF
'''Find the first file named 'fname' wich contains keyword 'keyword'
Search from the given path to upward.
'''
import vim
import os
from os.path import abspath, expanduser
import mmap
path    = vim.eval("a:path")
fname   = vim.eval("a:fname")
keyword = vim.eval("a:keyword")

def findFileUpward(path, fname, keyword):
    '''Find the first file named 'fname' wich contains keyword 'keyword'
    Search from the given path to upward.
    '''
    path = expanduser(abspath(path))
    fullname = path + os.sep + fname
    if os.path.exists(fullname):
        with open(fullname) as f:
            s = mmap.mmap(f.fileno(), 0, access=mmap.PROT_READ)
            if s.find(keyword) != -1:
                return path
        path = os.path.dirname(path)
        return findFileUpward(path, fname, keyword)
    else:
        return ""

#print(findFileUpward(path, fname, keyword))
vim.command("let ret = '{}'".format(findFileUpward(path, fname, keyword)))
EOF
    return ret
endfunc

let b:makeall_cmakebuilddir = 'build'
let b:makeall_binrunner = ""
let b:makeall_cmakeroot = ""

func! FindCMakeSrcRoot()
"Find the first CMakeLists.txt which contains keyword 'PROJECT'
"Search from the given path to upward.
    let b:makeall_cmakeroot =  FindFileWithContentsUp(expand("%:p:h"), 'CMakeLists.txt', 'PROJECT')
    if b:makeall_cmakeroot == ""
        return
    endif

    let builddir = b:makeall_cmakeroot."/".b:makeall_cmakebuilddir
    if !isdirectory(builddir)
        exe "setlocal makeprg=cmakecreate.sh\\ ".builddir
    else
        exe "setlocal makeprg=cmakemake.sh\\ ".builddir
        exe "let b:makeall_binrunner=\"".builddir."/\""
    endif
endfunc

func! RunTarget()
    if b:makeall_binrunner != ""
        let @p="!".b:makeall_binrunner
    else
        let @p="!./%<.elf"
    endif
endfunc

if !filereadable(expand("%:p:h")."/Makefile")
    setlocal makeprg=cc\ -Wall\ -Wextra\ -g\ -O0\ -o\ %<.elf\ %
endif

call FindCMakeSrcRoot()

nmap <F5> :call RunTarget()<cr>:<c-r>p

" FIXME get rid of using of `cmakecreate.sh` scripts
" FIXME cmake* script all conflate into plugin
" FIXME g: variable change to local variable
" TODO A command to create a new CMakeLists.txt
" TODO rewrite it after learnt vim scripting norm
" TODO A debug utils
