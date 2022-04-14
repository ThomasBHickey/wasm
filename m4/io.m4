;; io.m4
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

  (func $byte.read (result i32)
	(local $nread i32)(local $rbyte i32)
	(i32.store (global.get $readIOVsOff0) (global.get $readBuffOff))
	(i32.store (global.get $readIOVsOff4) (i32.const 1))
	(call $fd_read
	  (i32.const 0) ;; 0 for stdin
	  (global.get $readIOVsOff0) ;; *iovs
	  (i32.const 1) ;; iovs_len
	  (global.get $readIOVsOff4) ;; num bytes read goes here
	)
	drop  ;; $fd_read return value
	(local.set $nread (i32.load8_u (global.get $readIOVsOff4)))
	(if (i32.eqz (local.get $nread))
	  (return (global.get $maxNeg)))
	(return (i32.load8_u (global.get $readBuffOff)))
  )