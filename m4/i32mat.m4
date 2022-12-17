;;i32matrix.m4
  (global $i32M	  	i32	(i32.const 0x4D323369)) ;; 'i32M' type# for i32 Matices
  (func $i32Mat.mk (result i32)
	;; returns a memory offset for an i32matix pointer:
	;; 		typeNum, curLength, maxLength, dataOffset
	(local $lstPtr i32)
	(local.set $lstPtr (call $mem.get (i32.const 20))) 
	;; 4 bytes for type, 12 for the pointer info, 4 for first int32
	(call $setTypeNum (local.get $lstPtr)(global.get $i32M))
	(call $i32list.setCurLen (local.get $lstPtr) _0)
	(call $i32list.setMaxLen (local.get $lstPtr) _1)
	(call $i32list.setDataOff(local.get $lstPtr)
	(i32.add(local.get $lstPtr) _16)) ;; 16 bytes for header info
	(local.get $lstPtr)  ;; return ptr to the new list
  )
  (func $i32Mat.addRow (param $matPtr i32)(param $rowPtr i32)
    (call $i32list.push(local.get $matPtr)(local.get $rowPtr))
  )
  (func $i32Mat.get@ (param $matPtr i32)(param $row i32)(param $col i32)(result i32)
    (call $i32list.get@ (call $i32list.get@(param $row))(local.get $col))
  )
  (func $i32Mat.toStr (param $matPtr i32)
    _testString(`gIni32MtoStr', `in $i32M.toStr')
	(local $pstr i32)(local $rowNum i32)(local $numRows i32)
	(local.set $dstr (call $str.mk))  ;; display string
	(local.set $rowNum _0)(local.set $numRows (call $i32list.curLen (local.get $matPtr)))
	(loop $rowLoop
	  (if (i32.lt (local.get $rowNum)(local.get $numRows))
		(then
		  (call $str.catStr(local.get $dstr)(call $i32list.get@(local.get $matPtr)(local.get $rowNum)))
		  _incrLocal($rowNum)
		  (br $rowLoop)
		)
	  )
	)
	(local.get $dstr)
  )