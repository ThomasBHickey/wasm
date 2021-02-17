  (func $main (export "_start")
	(local $sp i32)(local $rsp i32)(local $stripped i32)
	(local.set $sp (call $str.mkdata (global.get $Hello1Data)))
	;; test multiple cat's
	(local.set $sp (call $str.mk))
	(call $str.catChar (local.get $sp) (i32.const 65))
	(call $str.catChar (local.get $sp) (i32.const 66))
	(call $str.catChar (local.get $sp) (i32.const 67))
	(call $str.catChar (local.get $sp) (i32.const 68))
	(call $str.catChar (local.get $sp) (i32.const 69))
	(call $str.catChar (local.get $sp) (i32.const 70))
	(call $i32.print (call $str.getDataOff (local.get $sp)))
	(local.set $rsp (call $str.Rev (local.get $sp)))
	(call $str.print (local.get $rsp))
	(call $str.catOntoStr (local.get $sp)(local.get $rsp))
	(call $str.print (local.get $sp))
	(call $str.LcatChar (local.get $sp)(i32.const 120)) ;; x
	(call $str.LcatChar (local.get $sp)(i32.const 120)) ;; x
	(call $str.print (local.get $sp))
	(local.set $stripped(call $str.stripLeading (local.get $sp)(i32.const 120))) ;; x
	(call $str.print (local.get $stripped))
	(call $i32.print (call $str.compare (local.get $sp)(local.get $rsp)))
  )
)