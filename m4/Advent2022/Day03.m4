;;Advent2022/Day03.m4
include(`stdHeaders.m4')

  ;; pass in two strings, return value of first char found in both
  (func $findSameChar (param $Lcomp i32)(param $Rcomp i32)(result i32)
	(local $cpos i32)(local $compLen i32)(local $char i32)
	(local $byte i32)

	(local.set $compLen (call $str.getByteLen (local.get $Lcomp)))  ;; assume both the same length!
	(local.set $cpos _0)
	(loop $cloop
	  (if (i32.lt_u (local.get $cpos)(local.get $compLen))
	    (then
	      (local.set $char (call $str.getByte (local.get $Lcomp)(local.get $cpos)))
		  ;;(call $byte.print(local.get $char))(call $printlf)
		  (if (i32.ne
				(call $str.index (local.get $Rcomp)(local.get $char))
				_maxNeg
				)
			(return (local.get $char)))
		  _incrLocal($cpos)
		  (br $cloop)
		)
	  )
	)
  _maxNeg ;; no duplicates
  )
  (func $day03a (export "_Day03a")
	(local $line i32) (local $score i32) (local $lineTerm i32)
	(local $lineLen i32)(local $halfLen i32)(local $priority i32)
	(local $Lcomp i32)(local $Rcomp i32)(local $sameChar i32)
	(local.set $score _0)
	(local.set $line (call $str.mk))
	;;(call $printwlf _maxNeg)
	(loop $lineLoop
	  (local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	  ;;(call $printwlf (local.get $line))
	  (local.set $lineLen (call $str.getByteLen (local.get $line)))
	  (local.set $halfLen (i32.shr_u (call $str.getByteLen (local.get $line)) _1))
	  ;;(call $printwlf (local.get $halfLen))
	  (local.set $Lcomp
	    (call $str.mkslice (local.get $line) _0 (local.get $halfLen)))
	  (local.set $Rcomp
	    (call $str.mkslice (local.get $line) (local.get $halfLen)(local.get $lineLen)))
	  ;;(call $printwlf (local.get $Lcomp))
	  ;;(call $printwlf (local.get $Rcomp))
	  (local.set $sameChar (call $findSameChar (local.get $Lcomp)(local.get $Rcomp)))
	  ;;(call $byte.print(local.get $sameChar))(call $printlf)
	  (if (i32.eq (local.get $sameChar) _maxNeg)
		(then
		  (call $printwlf _maxNeg)
		  (return)))
	  (if (i32.le_u (local.get $sameChar) _CHAR(`Z'))
		(local.set $priority (i32.sub (local.get $sameChar) (i32.const 38)))
		(else
		  (local.set $priority (i32.sub (local.get $sameChar) (i32.const 96))))
	  )
	  ;;(call $i32.print (local.get $priority))(call $printlf)
	  (local.set $score (i32.add (local.get $score)(local.get $priority)))
	  (if (i32.ne (local.get $lineTerm) _maxNeg)
	    (br $lineLoop))
	)
	(call $i32.print(local.get $score))(call $printlf)
  )
include(`../moduleTail.m4')
