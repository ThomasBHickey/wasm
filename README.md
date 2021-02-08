# Hand Written WebAssembly (Wasm)
Exploring hand written WebAssembly

An interest in minimal systems makes WebAssembly an attractive system
to explore.  That it appears to be rapidly becoming essential to the Web
makes it even more attractive since it will probably be supported for the
long term.

Decades ago I spent a couple of years programming in Xerox/Honeywell CPV's 
Macro Assembler, and once wrote a Forth compiler in assembler to give me better
string manipulation.  I expected that experience with Forth would help me
cope with WebAssembly's stack orientation, but the approach is so different
that not much seems to transfer.

Since most of my programming has centered around string manipulation,
writing a simple string package for Wasm seems like a reasonable first task.
The next project might be implementing Schorre's Meta II compiler
manipulation system.

My approach is to to do as much in WebAssembly as possible.  Currently the code's
external calls are to fd_read and fd_write as supported by github.com/bytecodealliance/wasmtime.
In addition to wasmtime I find it helpful to use WebAssembly/wabt/wat2wasm since
it often gives more informative diagnotics than wasmtime.  Other than that, it's
just me and a text editor.  Once I managed to print a single character, and then
dump an i32, I was able to build up some simple string routines.

string1.wat has some minimal string funcs that can create and display strings.
