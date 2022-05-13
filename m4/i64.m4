;; i64list.m4

  (global $i64L	  	i32	(i32.const 0x4C323369)) ;; 'i32L' type# for i32 lists
  _gnts(`gi64L', `i64L')

  _gnts(`gMaxNeg64AsString',`-9,223,372,036,854,775,808')
  _i64GlobalConst(maxNeg64, 0x8000000000000000)
  
  (func $i64.print (param $N i64)
	(call $str.print (call $i64.toStr (local.get $N)))
  )
  (func $i64.toStr (param $N i64)(result i32)
	;; return a string representing an i32
	(local $strPtr i32)
	(local.set $strPtr (call $str.mk))
	(call $i64.toStrHelper (local.get $strPtr)(local.get $N))
	(local.get $strPtr)
  )
  (func $i64.toStrHelper(param $strPtr i32)(param $N i64)
    (if (i64.eq (local.get $N)(global.get $maxNeg64))
	  (then
		(call $str.catStr (local.get $strPtr)(call $str.mkdata (global.get $gMaxNeg64AsString)))
		 return))
	(if (i64.lt_s (local.get $N)(i64.const 0))
	  (then
		(call $str.catByte(local.get $strPtr)(i32.const 45))  ;; hyphen
		(call $i64.toStrHelper (local.get $strPtr)(i64.sub (i64.const 0)(local.get $N)))
		return))
    (if (i64.ge_u (local.get $N)(i64.const 10))
	  (call $i64.toStrHelper
		(local.get $strPtr)
		(i64.div_u (local.get $N)(i64.const 10))))
	(call $str.catByte (local.get $strPtr)
	  (i32.add
		(i32.wrap_i64 (i64.rem_u (local.get $N)(i64.const 10)))
		;;(global.get $zero)))
		_CHAR(`0')))
  )
