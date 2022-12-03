;;Advent2022/Day01.m4
include(`stdHeaders.m4')
  (func $day01 (export "_Day01a")
    (local $line i32)(local $lineTerm i32)
	(local $elfCount i32)(local $elfCalories i32)
	(local $calories i32)
	(local $maxCalories i32)(local $maxElf i32)
	(local.set $line (call $str.mk))
	(local.set $maxCalories _0)
	(local.set $elfCount _0)
	(local.set $maxElf _0)
	(local.set $elfCalories _0)
	(loop $lineLoop
	  (local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	  ;;(call $print (local.get $line))
	  ;;(call $print (call $str.getByteLen (local.get $line)))
	  (local.set $calories (call $str.toI32 (local.get $line)))
	  (local.set $elfCalories (i32.add (local.get $elfCalories)(local.get $calories)))
	  (if (i32.eqz (call $str.getByteLen (local.get $line)))  ;; end of an elf
	    (then
		  (if (i32.gt_u (local.get $elfCalories)(local.get $maxCalories))
		   (then
			  (local.set $maxElf (local.get $elfCount))
			  ;;(call $printwlf (local.get $maxElf))
			  (local.set $maxCalories (local.get $elfCalories))
			))
		  _incrLocal($elfCount)
		  (local.set $elfCalories _0)
		  )
		)
	  (if (i32.ne (local.get $lineTerm) _maxNeg)
	    (br $lineLoop))
	)
	(call $print (local.get $maxElf))
	(call $printwlf (local.get $maxCalories))
  )
  (func $top3 (param $listPtr i32) (result i32)
	(local $t3 i32)(local $listPos i32)
	(local.set $t3 (call $i32list.mk))
	(call $i32list.qsort 
	  (local.get $listPtr)
	  _0 
	  (i32.sub (call $i32list.getCurLen (local.get $listPtr)) _1))
	(local.set $listPos (i32.sub (call $i32list.getCurLen (local.get $listPtr)) _1))
	(call $i32list.push (local.get $t3)(call $i32list.get@ (local.get $listPtr)(i32.sub (local.get $listPos) _0)))
	(call $i32list.push (local.get $t3)(call $i32list.get@ (local.get $listPtr)(i32.sub (local.get $listPos) _1)))
	(call $i32list.push (local.get $t3)(call $i32list.get@ (local.get $listPtr)(i32.sub (local.get $listPos) _2)))
	(local.get $t3)
  )
  (func $day01b (export "_Day01b")
    (local $line i32)(local $lineTerm i32)(local $top3calories i32)
	(local $elfCount i32)(local $elfCalories i32)
	(local $calories i32)
	(local $elves i32) ;; array with total calories for each elf
	(local $maxCalories i32)
	(local.set $line (call $str.mk))
	(local.set $elfCalories _0)
	(local.set $elves (call $i32list.mk))
	(loop $lineLoop
	  (local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	  (local.set $calories (call $str.toI32 (local.get $line)))
	  (local.set $elfCalories (i32.add (local.get $elfCalories)(local.get $calories)))
	  (if (i32.or (i32.eq (local.get $lineTerm) _maxNeg)(i32.eqz (call $str.getByteLen (local.get $line))))  ;; end of an elf
	    (then
		  (call $i32list.push (local.get $elves)(local.get $elfCalories))
		  (local.set $elfCalories _0)
		  )
		)
	  (if (i32.ne (local.get $lineTerm) _maxNeg)
	    (br $lineLoop))
	)
	(local.set $top3calories (call $top3 (local.get $elves)))
	;;(call $print (local.get $top3calories))
	(call $printwlf
	  (i32.add
		(i32.add
		  (call $i32list.get@ (local.get $top3calories) _0)
		  (call $i32list.get@ (local.get $top3calories) _1))
		(call $i32list.get@ (local.get $top3calories) _2)))
  )
include(`../moduleTail.m4')
