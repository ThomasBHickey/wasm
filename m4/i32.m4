;; i32.m4
  _gnts(`gMaxNegAsString',`-2147483648')
  _i32GlobalConst(maxNeg, 0x80000000)

  (func $i32.compare (param $i1 i32)(param $i2 i32)(result i32)
	(i32.eq (local.get $i1)(local.get $i2))
  )
  (func $i32.printOLD (param $N i32)	;; change this to more like the simple $i32.print below !!
										;; this avoids storage allocations while printing an i32
	(call $str.print (call $i32.toStr (local.get $N)))
  )
  (func $i32.toStr (param $N i32)(result i32)
	;; return a string representing an i32
	(local $strPtr i32)
	(local.set $strPtr (call $str.mk))
	(call $i32.toStrHelper (local.get $strPtr)(local.get $N))
	(local.get $strPtr)
  )
  (func $i32.toStrHelper(param $strPtr i32)(param $N i32)
    (if (i32.eq (local.get $N)(global.get $maxNeg))
	  (then
		(call $str.catStr (local.get $strPtr)(call $str.mkdata (global.get $gMaxNegAsString)))
		 return))
	(if (i32.lt_s (local.get $N)(i32.const 0))
	  (then
		(call $str.catByte(local.get $strPtr)(i32.const 45))  ;; hyphen
		(call $i32.toStrHelper (local.get $strPtr)(i32.sub (i32.const 0)(local.get $N)))
		return))
    (if (i32.ge_u (local.get $N)(i32.const 10))
	  (call $i32.toStrHelper
		(local.get $strPtr)
		(i32.div_u (local.get $N)(i32.const 10))))
	(call $str.catByte (local.get $strPtr)
	  (i32.add
		(i32.rem_u (local.get $N)(i32.const 10))
		_CHAR(`0')))
  )
(func $i32.print (param $N i32)
  (if (i32.ge_u (local.get $N)(i32.const 10))
    (call $i32.print (i32.div_u (local.get $N)(i32.const 10))))
  (call $byte.print
	  (i32.add
		(i32.rem_u (local.get $N)(i32.const 10))
		_CHAR(`0')))
)
