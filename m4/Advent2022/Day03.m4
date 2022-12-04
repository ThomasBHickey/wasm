;;Advent2022/Day03.m4
include(`stdHeaders.m4')

  (func $day03a (export "_Day03a")
	(local $line i32) (local $score i32) (local $lineTerm i32)
	(local $lineLen i32)(local $halfLen i32)
	(local $LRuck i32)(local $RRuck i32)
	(local.set $score _0)
	(local.set $line (call $str.mk))
	(loop $lineLoop
	  (local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	  (call $printwlf (local.get $line))
	  (local.set $lineLen (call $str.getByteLen (local.get $line)))
	  (local.set $halfLen (i32.shr_u (call $str.getByteLen (local.get $line)) _1))
	  (call $printwlf (local.get $halfLen))
	  (local.set $LRuck
	    (call $str.mkslice (local.get $line) _0 (local.get $halfLen)))
	  (local.set $RRuck
		(call $str.mkslice (local.get $line) (local.get $halfLen)(local.get $lineLen)))
	  (call $printwlf (local.get $LRuck))
	  (call $printwlf (local.get $RRuck))
	  (if (i32.ne (local.get $lineTerm) _maxNeg)
	    (br $lineLoop))
	)
	(call $printwlf (local.get $score))
  )
include(`../moduleTail.m4')
