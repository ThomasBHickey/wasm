changecom(`;;')dnl
define(`_module', `(module
  (import "wasi_unstable" "fd_read"
	(func $fd_read (param i32 i32 i32 i32)  (result i32)))
  (import "wasi_unstable" "fd_write"
	(func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory $1)
  (export "memory" (memory 0)))')dnl
define(`_endmodule', `)')dnl
define(`_CHAR',`(i32.const eval(32+index(` !"#$%& ()*+,-./0123456789:;<=>?@ABCDEFGHIJKOMNOPQRSTUVWXYZ[\]^_ abcdefghijklmnopqrstuvwxyz{|}~',$1)))')dnl
define(`_LEFTQ',(i32.const 39))dnl
define(`_TAB',(i32.const 9))dnl
define(`_CR',(i32.const 13))dnl
define(`_LF',(i32.const 10))dnl
define(`_SP',`_CHAR(` ')')dnl
define(`_SINGQUOTE',(i32.const 39))dnl
A: _CHAR(`A')
Z:_CHAR(`Z')
#: _CHAR(`#')
[:_CHAR(`[')
]:_CHAR(`]')
_:_CHAR(`_')
a: _CHAR(a)
~: _CHAR(`~')
LEFTQUOTE: _LEFTQ
(i32.const format(`0x%0x', _CHAR(`!')))
space:_SP
single quote: _SINGQUOTE
define(`provided', `0')
ifdef(`__unix__', `define(`provided', incr(provided))')
`provided:'provided
define(`_globalPos', `3000')dnl
first gpos:_globalPos
define(`_newGlobalPos2', `define(`_globalPos',eval(_globalPos+1+len($1)))')dnl
define(`_data',`divert(`1')(data (i32.const _globalPos) "$1\00")	(global $g$1 (i32 $_globalPos))_newGlobalPos2($1)
divert')dnl
_data(AAA)
Unrelated text between global definitions
_data(BB)
_data(CC)
undivert(`1')
