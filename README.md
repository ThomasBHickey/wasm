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
In addition to wasmtime I find wat2wasm (github.com/WebAssembly/wabt) which
often gives more informative diagnotics than wasmtime useful.  Other than that, it's
just me, a text editor and a bash shell.  The routines were built up from a
function to print a character to the console, then an i32, and from there
some useful string routines.  No Rust or Javascript involved from my point
of view.

So far, strings/string1.wat has a few minimal string functions to create and display strings.
