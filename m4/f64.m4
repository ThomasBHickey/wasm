;; f64list.m4

  (global $f64L	  	i32	(i32.const 0x4C343666)) ;; 'f64L' type# for f64 lists
  _gnts(`gf64L', `f64L')

;;  _gnts(`gMaxNeg64AsString',`-9,223,372,036,854,775,808')
;;  _i64GlobalConst(maxNeg64, 0x8000000000000000)
  
  (func $f64.print (param $F f64)
	(call $str.print (call $f64.toStr (local.get $F)))
  )
  (func $f64.toStr (param $F f64)(result i32)
	;; return a string representing an i32
	(local $strPtr i32)
	(local.set $strPtr (call $str.mk))
	(call $f64.toStrHelper (local.get $strPtr)(local.get $F))
	(local.get $strPtr)
  )
  (func $f64.toStrHelper(param $strPtr i32)(param $F f64)  ;; modifies string
    (local $I i64)  ;; same bits as $F
	(local $sign i64)(local $exp i64)(local $mant i64)
	(local $fAsStr i32)
	(local.set $I (i64.reinterpret/f64 (local.get $F)))
	(local.set $sign (i64.shr_u (local.get $I) (i64.const 63)))  ;; first bit
	(local.set $exp (i64.and (i64.shr_u (local.get $I)(i64.const 52))(i64.const 0x7ff)))
	(local.set $mant (i64.and (local.get $I)(i64.const 0xfffffffffffff)))
	(if (i32.wrap/i64 (local.get $sign))
	 (call $str.catByte(local.get $fAsStr) _CHAR(`-')))
	(call $str.catStr (local.get $fAsStr) (call $i64.toStr (local.get $exp)))
	(call $str.catByte(local.get $fAsStr) _CHAR(`:'))
	(call $str.catStr (local.get $fAsStr) (call $i64.toStr (local.get $mant)))
  )
