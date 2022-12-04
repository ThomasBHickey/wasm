;;Advent2022/Day03.m4
include(`stdHeaders.m4')

  (func $day03a (export "_Day03a")
	(local $line i32) (local $score i32)
	(local.set $score _0)
	(local.set $line (call $str.mk))
	(loop $lineLoop
	  (local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	  (local.set $score (i32.add (local.get $score) (call $map.get (local.get $scoreMap)(local.get $line))))
	  (call $printwlf (call $map.get (local.get $scoreMap)(local.get $line)))
	  (if (i32.ne (local.get $lineTerm) _maxNeg)
	    (br $lineLoop))
	)
	(call $printwlf (local.get $score))
	
  )