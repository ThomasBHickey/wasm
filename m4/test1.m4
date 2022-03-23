define(`_module', `(module
  (import "wasi_unstable" "fd_read"
	(func $fd_read (param i32 i32 i32 i32)  (result i32)))
  (import "wasi_unstable" "fd_write"
	(func $fd_write (param i32 i32 i32 i32) (result i32)))'
  (memory $1)
  (export "memory" (memory 0)))dnl
define(`_eludom', `)') dnl


_module(1025)
_eludom
