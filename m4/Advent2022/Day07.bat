m4 Day07.m4 >Day07.wat
#wasmtime run Day07.wat --invoke _Day07a < $1
wasmer run Day07.wat -i _Day07a < Day07.test
#wasmer run Day07.wat -i _Day07a < Day07.input
