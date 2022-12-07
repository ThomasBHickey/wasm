;;Advent2022/Day04.m4
include(`stdHeaders.m4')
  ;; expects a string such as "2-8"
  ;; a 'range' is an i32.list, e.g. [2, 8]
  (func $mkRange (param $chRange i32)(result i32)
    (local $split i32)(local $irange i32)
	(local.set $split (call $str.Csplit (local.get $chRange)_CHAR(`-')))
	(local.set $irange (call $i32list.mk))
	(call $i32list.push (local.get $irange) (call $str.toI32 (call $i32list.get@(local.get $split) _0)))
	(call $i32list.push (local.get $irange) (call $str.toI32 (call $i32list.get@(local.get $split) _1)))
	(local.get $irange)
  )
  ;; e.g. [2, 8] & 4 -> _1
  (func $isInRange (param $range i32)(param $member i32)(result i32)
    (i32.and 
		(i32.ge_u (local.get $member)(call $i32list.get@(local.get $range)_0))
		(i32.le_u (local.get $member)(call $i32list.get@(local.get $range) _1)))
  )
  ;; $i32.not not recognized??
  (func $i32not (param $t i32)(result i32)(if (local.get $t) (return _0))_1)
  ;; is one range fully contained in the second?
  (func $contained (param $leftRange i32)(param $rightRange i32)(result i32)
    (local $leftStart i32)(local $leftLast i32)(local $id i32)
	(local.set $leftStart (call $i32list.get@ (local.get $leftRange) _0))
	(local.set $leftLast  (call $i32list.get@ (local.get $leftRange) _1))
	(local.set $id (local.get $leftStart))
	(loop $check
	  (if (i32.le_u (local.get $id)(local.get $leftLast))
		(then
		  (if (call $i32not
		    (call $isInRange (local.get $rightRange)(local.get $id)) )
		    (return _0))
		  _incrLocal($id)
		  (br $check)
		)
	  )
	)
	_1  ;; contained
  )
  (func $overlap (param $leftRange i32)(param $rightRange i32)(result i32)
    (local $leftStart i32)(local $leftLast i32)(local $id i32)
	;;(call $i32.print _4)(call $printlf)
	;;(call  $printwlf (local.get $leftRange))
	(local.set $leftStart (call $i32list.get@ (local.get $leftRange) _0))
	(local.set $leftLast  (call $i32list.get@ (local.get $leftRange) _1))
	(local.set $id (local.get $leftStart))
	(loop $check
	  ;;(call $i32.print (local.get $id))(call $printlf)
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
  ;; Check for one contained in the other
  (func $decodePairA (param $line i32)(result i32)
    (local $halves i32)(local $leftSet i64)(local $rightSet i64)
	(local $leftRange i32)(local $rightRange i32)
	
	(local.set $halves (call $str.Csplit (local.get $line) (i32.const 44))) ;; split on comma
	;;(call $printwlf (local.get $halves))
	(local.set $rightRange (call $mkRange (call $i32list.pop (local.get $halves)))) ;; last one is the right side
	(local.set $leftRange  (call $mkRange (call $i32list.pop (local.get $halves))))
	(i32.or  ;; see if one range is fully contained in the other
	  (call $contained (local.get $leftRange)(local.get $rightRange))
	  (call $contained (local.get $rightRange)(local.get $leftRange)))
  )
  ;; Check for overlaps in sets
  (func $decodePairB (param $line i32)(result i32)
    (local $halves i32)(local $leftSet i64)(local $rightSet i64)
	(local $leftRange i32)(local $rightRange i32)
	
	(local.set $halves (call $str.Csplit (local.get $line) (i32.const 44))) ;; split on comma
	;;(call $printwlf (local.get $halves))
	(local.set $rightRange (call $mkRange (call $i32list.pop (local.get $halves)))) ;; last one is the right side
	(local.set $leftRange  (call $mkRange (call $i32list.pop (local.get $halves))))
	(call $overlap (local.get $leftRange)(local.get $rightRange))
  )
  (func $day04a (export "_Day04a")
    (local $line i32)(local $lineTerm i32)(local $score i32)
	(local.set $score _0)(local.set $line (call $str.mk))
	(loop $lineLoop
	  (local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	  (local.set $score
		(i32.add
		  (local.get $score)(call $decodePairA (local.get $line))))
	  (if (i32.ne (local.get $lineTerm) _maxNeg)
	    (br $lineLoop))
	)
	(call $i32.print(local.get $score))(call $printlf)
  )
  (func $day04b (export "_Day04b")
    (local $line i32)(local $lineTerm i32)(local $score i32)
	(local.set $score _0)(local.set $line (call $str.mk))
	(loop $lineLoop
	  (local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	  (local.set $score
		(i32.add
		  (local.get $score)(call $decodePairB (local.get $line))))
	  (if (i32.ne (local.get $lineTerm) _maxNeg)
	    (br $lineLoop))
	)
	(call $i32.print(local.get $score))(call $printlf)
  )
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
include(`../moduleTail.m4')
