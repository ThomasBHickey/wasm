;; table.m4
  ;; test function signatures
  (type $testSig (func (param i32)(result i32)))
  
  ;; comparison func signatures used by map
  (type $keyCompSig (func (param i32)(param i32)(result i32)))
  (type $keytoStrSig (func (param i32)(result i32)))
define(`_tableLength',`0')dnl
define(`_incrTableLength',`define(`_tableLength',eval(_tableLength+1))')dnl
define(`_addToTable', `divert(`2')  (;_tableLength;) $1
divert _incrTableLength')dnl
define(`_finishTable', `(table _tableLength funcref)
 (elem (i32.const 0)
undivert(`2'))')dnl
  _addToTable($str.compare)
  _addToTable($str.toStr)
  _addToTable($i32.compare)
  _addToTable($i32.toStr)
  _gdef(`gFirstTestOffset',_tableLength)
  _addToTable($str.catByte.test)
  _finishTable
  