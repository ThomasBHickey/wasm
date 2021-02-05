(module
  (import "wasi_unstable" "fd_read" 
    (func $fd_read 
      (param i32 i32 i32 i32) 
      (result i32)))
  (import "wasi_unstable" "fd_write" 
    (func $fd_write 
      (param i32 i32 i32 i32) 
      (result i32)))
  (memory 1)
  (export "memory" (memory 0))
  (data (i32.const 300) "ABC\0A\00") ;; something to write

  (func $print_i32 (param $N i32)
	(local $zero i32)
	(local.set $zero (i32.const 48))
	;; iovs start at 200, buffer at 300
	(i32.store (i32.const 200) (i32.const 300))
	(i32.store (i32.const 204) (i32.const 10))
	;; Compute char value for the number mod 10, store a offset 300
	(i32.store
		(i32.const 300)
		(i32.add
			(i32.rem_u (local.get $N)(i32.const 10))
			(local.get $zero)))
	(call $fd_write
		(i32.const 1) ;; stdout
		(i32.const 200) ;; *iovs
		(i32.const 1) ;; # iovs
		(i32.const 0) ;; length?
	)
	drop);;print_i.32

  (func $main (export "_start")
	(local $loopCount i32)

    ;; buffer of 100 chars to read into
    (i32.store (i32.const 4) (i32.const 12))
    (i32.store (i32.const 8) (i32.const 100))
	(set_local $loopCount (i32.const 0))
  (loop $echoLoop
    (call $fd_read
      (i32.const 0) ;; 0 for stdin
      (i32.const 4) ;; *iovs
      (i32.const 1) ;; iovs_len
      (i32.const 8) ;; nread
    )
    drop
    (call $fd_write
      (i32.const 1) ;; 1 for stdout
      (i32.const 4) ;; *iovs 
      (i32.const 1) ;; iovs_len
      (i32.const 0) ;; nwritten
    )
    drop
	(get_local $loopCount)
	(i32.const 1)
	(i32.add)
	(set_local $loopCount)
	(call $print_i32 (get_local $loopCount))
	;;drop
	(br_if $echoLoop (i32.lt_u (get_local $loopCount)(i32.const 11)))
  )
  );; $main
)