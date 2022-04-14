;; io.m4
  (global $readIOVsOff0 	i32 (i32.const 0))
  (global $readIOVsOff4 	i32 (i32.const 4))
  (global $readBuffOff 		i32 (i32.const 8))
  (global $readBuffLen 		i32 (i32.const 4))
  (global $writeIOVsOff0 	i32 (i32.const 16))
  (global $writeIOVsOff4 	i32 (i32.const 20))
  (global $writeBuffOff 	i32 (i32.const 24))
  (global $writeBufLen 		i32 (i32.const 4))
  (global $bytesRead		i32 (i32.const 4))
  (global $bytesWritten		(mut i32) (i32.const 0))

  (func $io.initialize
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
	(global.set $bytesWritten (i32.add (global.get $bytesWritten)(i32.const 1)))
  )
