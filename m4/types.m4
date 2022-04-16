;; types.m4
  (func $getTypeNum(param $ptr i32)(result i32)
	(i32.load (local.get $ptr))
  )
  (func $setTypeNum(param $ptr i32)(param $typeNum i32)
	(i32.store (local.get $ptr)(local.get $typeNum))
  )
