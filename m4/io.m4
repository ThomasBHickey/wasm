;; io.m4
  (global $writeIOVsOff0 	i32 (i32.const 2300))
  ;;(global $writeIOVsOff0 	i32 (call $mem.get (i32.const 4)))
  (global $writeIOVsOff4 	i32 (i32.const 2304))
  (global $writeBuffOff 	i32 (i32.const 2400))
  (global $writeBufLen 		i32 (i32.const 512))

  (func $io.initialize
	(global.set $writeIOVsOff0 (call $mem.get(i32.const 4)))
  )
  (func $byte.print (param $B i32)
	(i32.store (global.get $writeIOVsOff0)(global.get $writeBuffOff))
	(i32.store (global.get $writeIOVsOff4)(i32.const 1))
	(i32.store
		(global.get $writeBuffOff)
		(local.get $B))
	(call $fd_write
		(i32.const 1) ;; stdout
		(global.get $writeIOVsOff0)
		(i32.const 1) ;; # iovs
		(i32.const 0) ;; length?
	)
	drop
  )
