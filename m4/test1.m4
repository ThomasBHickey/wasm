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
define(`_LEFTQ',(i32.const 39))
define(`_TAB',(i32.const 9))
define(`_CR',(i32.const 13))
define(`_LF',(i32.const 10))
define(`_SP',`_CHAR(` ')')
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
