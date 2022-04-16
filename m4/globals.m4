;; globals.m4
  _i32ConstGlob(maxNeg, 0x80000000)
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
  (global $i32L	  	i32	(i32.const 0x6933324C)) ;; 'i32L' type# for i32 lists
  (global $i64L		i32 (i32.const 0x6936344C)) ;; 'i64L' type# for i64 lists
  (global $BStr		i32	(i32.const 0x42537472))	;; 'BStr' type# for byte strings
