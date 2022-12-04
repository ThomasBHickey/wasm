;; f64list.m4

  (global $f64L	  	i32	(i32.const 0x4C343666)) ;; 'f64L' type# for f64 lists
  _gnts(`gf64L', `f64L')
  
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
	(local.set $I (i64.reinterpret/f64 (local.get $F)))
	(call $i64.hexprint(local.get $I))(call $printlf)
	(local.set $sign (i64.shr_u (local.get $I) (i64.const 63)))  ;; first bit
	(call $printwlf (call $i64.toStr (local.get $sign)))
	(local.set $exp (i64.and (i64.shr_u (local.get $I)(i64.const 52))(i64.const 0x7ff)))
	(local.set $exp (i64.sub (local.get $exp)(i64.const 1023)))
	(call $printwlf (call $i64.toStr (local.get $exp)))
	(local.set $mant (i64.and (local.get $I)(i64.const 0xfffffffffffff)))
	;;(call $printwlf (call $i64.toStr (local.get $mant)))
	(if (i32.wrap/i64 (local.get $sign))
	 (call $str.catByte(local.get $strPtr) _CHAR(`-')))
	(call $str.catStr (local.get $strPtr) (call $i64.toStr (local.get $exp)))
	(call $str.catByte(local.get $strPtr) _CHAR(`:'))
	(call $str.catStr (local.get $strPtr) (call $i64.toStr (local.get $mant)))
  )
_addToTable($f64.toStr.test)
(func $f64.toStr.test (param $testNum i32)(result i32)
  (local $f f64)
  (local.set $f (f64.const -2))
  (call $printwlf (call $f64.toStr (local.get $f)))
  (i32.const 0)
)