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
  (;
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
  ;)
  (func $char2priority (param $char i32)(result i32)
	  (if (i32.le_u (local.get $char) _CHAR(`Z'))
		(return (i32.sub (local.get $char) (i32.const 38))))
	  (i32.sub (local.get $char) (i32.const 96))
  )
  (func $read3lines (result i32)
	(local $3lines i32)(local $line i32)
	(local.set $3lines (call $i32list.mk))  ;; array for the lines
    (local.set $line (call $str.read))
	(if (i32.eq (local.get $line) _maxNeg) (return _maxNeg))  ;; check first line of triple
	(call $i32list.push (local.get $3lines)(local.get $line))
	;; Assume there are at least a couple more lines
	(call $i32list.push (local.get $3lines)(call $str.read))
	(call $i32list.push (local.get $3lines)(call $str.read))
	(local.get $3lines)
  )
  (func $findCommon (param $3lines i32)(result i32)
    (local $curChar i32)(local $firstLen i32)(local $curPos i32)
	(local $firstLine i32)(local $secondLine i32)(local $thirdLine i32)
	(local.set $curPos _0)
	(local.set $firstLine (call $i32list.get@ (local.get $3lines) _0))
	(local.set $firstLen (call $str.getByteLen (local.get $firstLine)))
	(local.set $secondLine (call $i32list.get@ (local.get $3lines) _1))
	(local.set $thirdLine (call $i32list.get@ (local.get $3lines) _2))
	;;(call $printwlf (local.get $firstLine))
	(loop $cloop
	  (if (i32.lt_u (local.get $curPos)(local.get $firstLen))
	   (then
	    (local.set $curChar (call $str.getByte (local.get $firstLine)(local.get $curPos)))
		(if
		  (i32.and
			(i32.ne (call $str.index (local.get $secondLine)(local.get $curChar)) _maxNeg)
			(i32.ne (call $str.index (local.get $thirdLine) (local.get $curChar)) _maxNeg))
		  (return (local.get $curChar)))
		))
	  _incrLocal($curPos)
	  (br $cloop)
	)
	_maxNeg
  )
  (func $day03b (export "_Day03b")
	(local $3lines i32)(local $comChar i32)(local $sum i32)
	(local.set $sum _0)
	
	(loop $3loop
	  (local.set $3lines (call $read3lines))
	  (if (i32.eq (local.get $3lines) _maxNeg)
		(then
		  (call $i32.print (local.get $sum))(call $printlf)
		  (return)))
	  ;;(call $printwlf (local.get $3lines))
	  (local.set $comChar (call $findCommon (local.get $3lines)))
	  ;;(call $byte.print (local.get $comChar))(call $printlf)
	  (local.set $sum (i32.add 
		(local.get $sum)
		(call $char2priority (local.get $comChar))))
	  (br $3loop)
	)
  )
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
include(`../moduleTail.m4')
