;;Advent2022/Day05.m4
include(`stdHeaders.m4')


(func $addRowToStacks (param $stacks i32)(param $line i32)
	(local $numStacks i32)(local $rowPos i32)
	(local.set $rowPos _1)  ;; second colum has first crate
	
	(local.set $numStacks
	  (i32.div_u (i32.add (call $str.getByteLen(local.get $line)) _1) _4))
)
(func $readInStacks (result i32) ;; returns list of stacks
  ;; each stack is a list of crates (top crate first)
	(local $line i32)(local $lineTerm i32)
	(local $stacks i32)(local $stackNum i32)(local $cpos i32)
	(local $c i32) ;; char
	(local.set $stacks (call $i32list.mk))
	(local.set $stackNum _0)
	(local.set $line (call $str.mk))
	(loop $lineLoop
	  (call $i32.print _7)
	  (local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	  (local.set $cpos (i32.mul (local.get $stackNum) _4)) _incrLocal($cpos)
	  (local.set $c (call $str.getByte (local.get $line)(local.get $cpos)))
	  (call $printwlf (local.get $line))
	  (call $byte.print(local.get $c))(call $printlf)
	  (if (call $str.getByteLen(local.get $line))
		(br $lineLoop))
	)
	(local.set $lineTerm (call $str.readIntoStr (local.get $line)))
	(call $i32.print (call $str.getByteLen (local.get $line)))(call $printlf)
	(local.get $stacks)
)
(func $printStacks
	
)

(func $day05a (export "_Day05a")
    (local $line i32)(local $lineTerm i32)(local $lineLen i32)
	(local $numStacks i32) (local $stacks i32)
	(local.set $stacks (call $readInStacks))
	(call $printwlf (local.get $stacks))
)
include(`../moduleTail.m4')
