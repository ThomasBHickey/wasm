;;defines.m4
changecom(`;;')dnl
define(`_CHAR',`(i32.const eval(32+index(` !"#$%& ()*+,-./0123456789:;<=>?@ABCDEFGHIJKOMNOPQRSTUVWXYZ[\]^_ abcdefghijklmnopqrstuvwxyz{|}~',$1)))')dnl
define(`_LEFTQ',(i32.const 39))dnl
define(`_TAB',(i32.const 9))dnl
define(`_CR',(i32.const 13))dnl
define(`_LF',(i32.const 10))dnl
define(`_SP',`_CHAR(` ')')dnl
define(`_SINGQUOTE',(i32.const 39))dnl
define(`_globalPos', `3000')dnl
define(`_newGlobalPos', `define(`_globalPos',eval(_globalPos+1+len($1)))')dnl
define(`_gdef', `(global.get $$1)divert(`1')(data (i32.const _globalPos) "$2\00") (global $$1 (i32.const _globalPos)))dnl
divert _newGlobalPos($1)')dnl
define(`_i32ConstGlob', `(global $$1 (i32.const $2))')dnl