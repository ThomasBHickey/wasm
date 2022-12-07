;;Advent2022/Day04.m4
include(`stdHeaders.m4')
  ;; expects a string such as "2-8"
  ;; a 'range' is an i32.list, e.g. [2, 8]
  (func $mkRange (param $chRange i32)(result i32)
    (local $split i32)(local $irange i32)
	;;(call $printwlf (local.get $chRange))
	(local.set $split (call $str.Csplit (local.get $chRange)_CHAR(`-')))
	;;(call $printwlf (local.get $split))
	(local.set $irange (call $i32list.mk))
	(call $i32list.push (local.get $irange) (call $str.toI32 (call $i32list.get@(local.get $split) _0)))
	(call $i32list.push (local.get $irange) (call $str.toI32 (call $i32list.get@(local.get $split) _1)))
	;;(call $i32list.print (local.get $irange))
	(local.get $irange)
  )
  ;; e.g. [2, 8] & 4 -> _1
  (func $isInRange (param $range i32)(param $member i32)(result i32)
    (call $print (local.get $range))(call $i32.print (local.get $member))(call $printlf)
    (i32.and 
		(i32.ge_u (local.get $member)(call $i32list.get@(local.get $range)_0))
		(i32.le_u (local.get $member)(call $i32list.get@(local.get $range) _1)))
  )
  ;; [5, 7] & [7, 9]  -> _1
  (func $overlap (param $leftRange i32)(param $rightRange i32)(result i32)
    (local $leftStart i32)(local $leftLast i32)(local $id i32)
	(call $i32.print _4)(call $printlf)
	(call  $printwlf (local.get $leftRange))
	(local.set $leftStart (call $i32list.get@ (local.get $leftRange _0)))
	(local.set $leftLast  (call $i32list.get@ (local.get $leftRange _1)))
	(call $i32.print (local.get $leftStart))(call $printlf)
	(call $i32.print (local.get $leftLast))(call $printlf)
	(local.set $id (local.get $leftStart))
	(call $printwlf (local.get $leftRange))(call $printwlf(local.get $rightRange))
	(loop $check
	  (call $i32.print (local.get $id))(call $printlf)
	  (if (i32.le_u (local.get $id)(local.get $leftLast))
		(then
		  (if (call $isInRange (local.get $rightRange)(local.get $id))
		    (return _1))
		  _incrLocal($id)
		  (br $check)
		)
	  )
	)
	_0  ;; no overlap
  )
  (func $decodePair (param $line i32)(result i32)
    (local $halves i32)(local $leftSet i64)(local $rightSet i64)
	(local $leftRange i32)(local $rightRange i32)
	
	(call $printwlf (local.get $line))
	(local.set $halves (call $str.Csplit (local.get $line) (i32.const 44))) ;; split on comma
	(call $printwlf (local.get $halves))
	(local.set $rightRange (call $mkRange (call $i32list.pop (local.get $halves)))) ;; last one is the right side
	(local.set $leftRange  (call $mkRange (call $i32list.pop (local.get $halves))))
	(call $print (local.get $leftRange))
	(call $print (local.get $rightRange))(call $printlf)
	(call $overlap (local.get $leftRange)(local.get $rightRange))
  )
  (func $day04a (export "_Day04a")
    (local $line i32)(local $lineTerm i32)(local $score i32)
	(local.set $score _0)(local.set $line (call $str.mk))
	(loop $lineLoop
	  (local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	  (call $str.print(local.get $line))(call $printlf)
	  (local.set $score
		(i32.add
		  (local.get $score)(call $decodePair (local.get $line))))
	  (call $i32.print (local.get $score))(call $printlf)
	  (if (i32.ne (local.get $lineTerm) _maxNeg)
	    (br $lineLoop))
	)
	(call $i32.print(local.get $score))(call $printlf)
  )
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
include(`../moduleTail.m4')
