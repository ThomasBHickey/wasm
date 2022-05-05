;; types.m4
  (func $getTypeNum(param $ptr i32)(result i32)
	(i32.load (local.get $ptr))
  )
  (func $setTypeNum(param $ptr i32)(param $typeNum i32)
	(i32.store (local.get $ptr)(local.get $typeNum))
  )
  _gnts(`gExpectedType', `Type error. Expected:')
  _gnts(`gFound:', `Found:')
  (func $typeError (param $typeFound i32)(param $typeExpected i32)
    (call $printwsp (global.get $gExpectedType))
	(call $printwlf (call $typeNum.toStr (local.get $typeExpected)))
	(call $printwsp (global.get $gFound:))
	(call $printwlf (call $typeNum.toStr (local.get $typeFound)))
	(call $error2)
  )
  (func $typeNum.toStr (param $typeNum i32)(result i32)
    (local $strptr i32)
	(local.set $strptr (call $str.mk))
    (call $str.catByte (local.get $strptr)(i32.shr_u (local.get $typeNum)(i32.const 24)))
	(call $str.catByte (local.get $strptr)(i32.shr_u (local.get $typeNum)(i32.const 16)))
	(call $str.catByte (local.get $strptr)(i32.shr_u (local.get $typeNum)(i32.const 8)))
	(call $str.catByte (local.get $strptr)(i32.shr_u (local.get $typeNum)(i32.const 0)))
	(local.get $strptr)  ;;return the new string
  )
  (func $typeNum.toStr.test (param $testNum i32)(result i32)
    (call $str.printwlf (call $i32.toStr (global.get $i32L)))
	(call $printwlf (global.get $gi32L))
	(i32.eqz
	  (call $str.compare
		(call $typeNum.toStr (global.get $i32L)) ;; i32 value
		(call $str.mkdata (global.get $gi32L))))	;; null terminated string
  )
  _gnts(`gBoundsError',`Bounds Error!')
  (func $boundsError (param $pos i32)(param $max i32)
    (call $printwsp (global.get $gBoundsError))
	(call $printwsp (local.get $pos))
	(call $printwlf (local.get $max))
	(call $error2)
  )
