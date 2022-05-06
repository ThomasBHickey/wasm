  (func $day1 (export "_Day1a")
    (local $lines i32)(local $pairs i32)(local $greaterCount i32)
	(local $pairsLen i32)(local $pairPos i32)(local $pair i32)
	(local $p1val i32)(local $p2val i32)
	(local.set $lines (call $readFileSlow))
	(local.set $pairs (call $tplwise (local.get $lines)(i32.const 2)))
	(local.set $pairsLen (call $i32list.getCurLen (local.get $pairs)))
	(local.set $greaterCount (i32.const 0))
	(local.set $pairPos (i32.const 0))
	(loop $pairLoop
	  (local.set $pair
		(call $i32list.get@ (local.get $pairs)(local.get $pairPos)))
	  (local.set $p1val (call $str.toI32 (call $i32list.get@ (local.get $pair)(i32.const 0))))
	  (local.set $p2val (call $str.toI32 (call $i32list.get@ (local.get $pair)(i32.const 1))))
	  (if (i32.lt_u (local.get $p1val)(local.get $p2val))
		(local.set $greaterCount (i32.add (local.get $greaterCount)(i32.const 1))))
	  (local.set $pairPos (i32.add (local.get $pairPos)(i32.const 1)))
	  (if (i32.lt_u (local.get $pairPos)(local.get $pairsLen))
	    (br $pairLoop))
	)
	(call $printwlf (local.get $greaterCount))
  )