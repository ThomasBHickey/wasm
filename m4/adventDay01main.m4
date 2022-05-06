;; adventDay01main.m4
  (func $tplwise (param $lstPtr i32)(param $winSize i32)(result i32)
	(local $tplPtr i32)(local $lstPos i32)(local $lstLen i32)
	(local $tplListPtr i32)(local $posInTpl i32)
	(local.set $lstPos (i32.const 0))
	(local.set $lstLen (call $i32list.getCurLen (local.get $lstPtr)))
	;;(call $printwlf (local.get $lstLen))
	(local.set $tplListPtr (call $i32list.mk)) ;; list of tuples
	(loop $tplLoop
	  (if		;; no more tuples?
		(i32.ge_u
		  (i32.add (local.get $lstPos)(i32.sub (local.get $winSize)(i32.const 1)))
		  (local.get $lstLen)
		  )
		(return (local.get $tplListPtr)))
	  (local.set $tplPtr (call $i32list.mk))
	  (local.set $posInTpl (i32.const 0))
	  (loop $mkTpl
		(call $i32list.push
		  (local.get $tplPtr)
		  (call $i32list.get@
			(local.get $lstPtr)
			(i32.add (local.get $lstPos)(local.get $posInTpl)))
		)
		(local.set $posInTpl (i32.add (local.get $posInTpl)(i32.const 1)))
		(if (i32.lt_u (local.get $posInTpl)(local.get $winSize))
		  (br $mkTpl))
	  )
	  ;;(call $printwlf (local.get $tplPtr))
	  (call $i32list.push (local.get $tplListPtr)(local.get $tplPtr))
	  (local.set $lstPos (i32.add (local.get $lstPos)(i32.const 1)))
	  (br $tplLoop)
	)
	(local.get $tplListPtr)
  )
  (func $day1 (export "_day1")
    (local $lines i32)(local $pairs i32)(local $greaterCount i32)
	(local $pairsLen i32)(local $pairPos i32)(local $pair i32)
	(local $p1val i32)(local $p2val i32)
	(local.set $lines (call $readFileAsStrings))
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
	(call $i32.print (local.get $greaterCount))(call $printlf)
  )
