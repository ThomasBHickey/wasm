;;Advent2022/Day05.m4
include(`stdHeaders.m4')


(func $addRowToStacks (param $stacks i32)(param $line i32)
	(local $numStacks i32)(local $rowPos i32)
	(local.set $rowPos _1)  ;; second colum has first crate
	
	(local.set $numStacks
	  (i32.div_u (i32.add (call $str.getByteLen(local.get $line)) _1) _4))
)
(func $readStacks (result i32) ;; returns list of stacks
  ;; each stack is a list of crates (top crate first)
	(local $line i32)(local $lineTerm i32)
	(local $stacks i32)(local $stackNum i32)(local $cpos i32)
	(local $stack i32)
	(local $c i32) ;; char
	(local.set $stacks (call $i32list.mk))
	(local.set $line (call $str.mk))
	(loop $lineLoop
	  (local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	  (local.set $cpos _1)  ;; where first crate (might be)
	  (local.set $stackNum _0)
	  (loop $stackLoop
	    ;;_testString(`stackLoop',`In stackLoop')
		(if (i32.le_u (call $i32list.getCurLen(local.get $stacks))(local.get $stackNum))
		  (call $i32list.push (local.get $stacks)(call $i32list.mk)))
		(local.set $stack (call $i32list.get@ (local.get $stacks)(local.get $stackNum)))
		_incrLocal($stackNum)
		(local.set $c (call $str.getByte (local.get $line) (local.get $cpos)))
		(if (i32.ne (local.get $c) _SP)  ;; push it on stack if not empty
		  (call $i32list.push (local.get $stack)(local.get $c)))
		(local.set $cpos (i32.add (local.get $cpos) _4))
		(if (i32.lt_u (local.get $cpos)(call $str.getByteLen (local.get $line)))
		  (br $stackLoop))
	  )
	  ;;(call $printwlf (local.get $line))
	  (if (call $str.getByteLen(local.get $line))
		(br $lineLoop))
	)
	;;(local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	(local.get $stacks)
)
(func $printStacks (param $stacks i32)
  (local $stack i32)(local $stackNum i32)(local $numCrates i32)(local $crateNum i32)
  (local.set $stackNum _0)
  ;;(call $printwlf (local.get $stacks))
  (loop $stackLoop
    (local.set $stack (call $i32list.get@(local.get $stacks)(local.get $stackNum)))
	_incrLocal($stackNum)
	(local.set $crateNum _0)
	(loop $crateLoop
	  (call $byte.print (call $i32list.get@(local.get $stack)(local.get $crateNum)))
	  _incrLocal($crateNum)
	  (if (i32.lt_u (local.get $crateNum)(call $i32list.getCurLen(local.get $stack)))
		(br $crateLoop)))
	(call $printlf)
	(if (i32.lt_u (local.get $stackNum)(call $i32list.getCurLen(local.get $stacks)))
	  (br $stackLoop))
  )
)
(func $readMoves (result i32)
  (local $move i32)(local $moves i32)(local $line i32)(local $lineTerm i32)
  (local $stackNum i32)(local $chunks i32)
  (local.set $moves (call $i32list.mk))
  (local.set $line (call $str.mk))
  
  (loop $lineLoop
	(local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	;;(call $printwlf (local.get $line))
	(local.set $chunks (call $str.Csplit (local.get $line) _SP))
	;;(call $printwlf (local.get $chunks))
	(local.set $move (call $i32list.mk))
	(call $i32list.push (local.get $move)(call $str.toI32(call $i32list.get@ (local.get $chunks) _1)))
	(call $i32list.push (local.get $move)(call $str.toI32(call $i32list.get@ (local.get $chunks) _3)))
	(call $i32list.push (local.get $move)(call $str.toI32(call $i32list.get@ (local.get $chunks) _5)))
	(call $i32list.push (local.get $moves)(local.get $move))
	(if (i32.ne (local.get $lineTerm) _maxNeg)
	  (br $lineLoop))
  )
  (local.get $moves)
)
(;;
(func $i32list.reverse (param $lstPtr i32)(result i32)
  (local $revList i32)(local $pos i32)
  (local.set $revList (call $i32list.mk))
  (local.set $pos _0)
  (loop $posLoop
    (if (i32.eqz (call $i32list.getCurLen (local.get $lstPtr)))
	  (return (local.get $revList)))
	(call $i32list.push (local.get $revList)(call $i32list.get@ (local.get $lstPtr)(local.get $pos)))
	_incrLocal($pos)
  )
  (local.get $revList)
)
;;)
(func $printMoves (param $moves i32)
  (call $printwlf (local.get $moves))
)
(func $doMoves (param $stacks i32)(param $moves i32)
  (local $moveSize i32)(local $moveFrom i32)(local $moveTo i32)
  (local $move i32)(local $movePos i32)
  (local.set $movePos _0)
  (loop $moveLoop
	(local.set $move (call $i32list.get@ (local.get $moves)(local.get $movePos)))
	;;(call $printwlf (local.get $move))
	(local.set $moveSize (call $i32list.get@ (local.get $move) _0))
	(local.set $moveFrom (call $i32list.get@ (local.get $move) _1))
	(local.set $moveTo   (call $i32list.get@ (local.get $move) _2))
	
	_incrLocal($movePos)
	(if (i32.lt_u (local.get $movePos)(call $i32list.getCurLen (local.get $moves)))
	  (br $moveLoop))
  )
  
)
(func $day05a (export "_Day05a")
	(local $moves i32)(local $stacks i32)
	(local.set $stacks (call $readStacks))
	(call $printStacks (local.get $stacks))
	(local.set $moves (call $readMoves))
	(call $printMoves (local.get $moves))
	;;(call $doMoves (local.get $stacks)(local.get $moves))
	(call $printStacks (local.get $stacks))
)
include(`../moduleTail.m4')
