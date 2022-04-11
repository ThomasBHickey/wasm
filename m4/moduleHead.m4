;;moduleHead.m4
;; run resulting file via "wasmtime run xxx.wat" 
;; (wasmtime recognizes the func exported as "_start")
;; or "wasmtime string1.wasm" if it has been compiled by
;; "wat2wasm --enable-bulk-memory string1.wat"
;; run tests: "wasmtime run xxx.wat --invoke _test"
(module
  (import "wasi_unstable" "fd_read"
	(func $fd_read (param i32 i32 i32 i32)  (result i32)))
  (import "wasi_unstable" "fd_write"
	(func $fd_write (param i32 i32 i32 i32) (result i32)))
