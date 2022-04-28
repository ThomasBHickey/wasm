;; table.m4
  ;; test function signatures
  (type $testSig (func (param i32)(result i32)))
define(`_tableLength',`0')dnl
define(`_incrTableLength',`define(`_tableLength',eval(_tableLength+1))dnl')dnl
define(`_addToTable', `divert(`2')    (;_tableLength;) $1
divert _incrTableLength')dnl
define(`_finishTable',`(table _tableLength funcref)
  (elem (i32.const 0)
undivert(`2')  )')dnl

  _addToTable($str.compare)
  _addToTable($str.toStr)
  _addToTable($i32.compare)
  _addToTable($i32.toStr)
  divert(`1')  (global $gFirstTestOffset i32 (i32.const _tableLength))
divert
  _addToTable($str.catByte.test)
  _addToTable($str.catStr.test)
  _finishTable
divert(`1')  (global $tableLength  i32 (i32.const _tableLength))
divert
  (func $test (export "_test")
	;; Run tests: wasmtime run XXX.wat --invoke _test
	(local $testOff i32)
	(local $oldCurMemUsed i32)
	(local.set $testOff (global.get $gFirstTestOffset))
	(local.set $oldCurMemUsed (global.get $curMemUsed))
	(loop $testLoop
	  (if (i32.lt_u (local.get $testOff)(global.get $tableLength))
	    (then
		  (local.get $testOff)
		  (call $Test.show
			(local.get $testOff)
			(call_indirect
			  (type $testSig)
			  (local.get $testOff)))
		  _incrLocal($testOff)
		  (br $testLoop)
		)
	  )
	)
	(call $reclaimMem (local.get $oldCurMemUsed))
	(call $showMemUsed)
  )
  (func $Test.show (param $testNum i32)(param $testResult i32)
	(if (local.get $testResult)
	  (then
	    (call $Test.showFailed
		  (local.get $testNum)
		  (local.get $testResult)))
	  (else
		(call $Test.showOK (local.get $testNum))))
  )
  (func $Test.printTest
    (call $byte.print _CHAR(`T'))
	(call $byte.print _CHAR(`e'))
	(call $byte.print _CHAR(`s'))
	(call $byte.print _CHAR(`t'))
	(call $printsp)
  )
  (func $Test.showOK (param $testnum i32)
    (call $Test.printTest)
	(call $i32.print (local.get $testnum))
	(call $printsp)
	(call $byte.print _CHAR(`O'))
	(call $byte.print _CHAR(`K'))
	(call $printlf)
  )
  (func $Test.showFailed (param $testnum i32)(param $testResult i32)
    (call $Test.printTest)
	(call $i32.print (local.get $testnum))
	(call $printsp)
	(call $byte.print _CHAR(`N'))
	(call $byte.print _CHAR(`O'))
	(call $byte.print _CHAR(`K'))
	(call $byte.print _CHAR(`!'))
	(call $byte.print _CHAR(`!'))
	(call $printsp)
	(call $i32.print (local.get $testResult))
	(call $printlf)
	)

