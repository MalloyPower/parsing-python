### Multiple front-ends for Python

The code in this directory builds the running front-ends for Python in
two flavours:

- bison-front-end: you'll need a system with gcc, flex and bison
- menhir-front-end: you'll need a system with ocaml, ocamllex and menhir

For the record, these are the versions we have used:

- gcc version 5.4.0,
- flex version 2.6.0
- bison version 3.0.4
- ocaml version 4.02.3
- ocamllex version 4.02.3
- menhir version 20151112

You can see the parsers and scanners in the relevant sub-directories.

Both front-ends use the generated conflict-free parsers as well as
version-specific scanners in the scanners/ sub-directory.  The
scanners are mostly the same in each case: there's a series 2 and
series 3 scanner, and then we do some minor edits (mostly using sed
and grep to add/remove keywords) to get version-specific scanners.
The scanners (flex/ocamllex files) are all there, so this part should
be transparent, but see the scanners/Makefile if you want to rebuild
them.


#### Building

To build a front-end for a Python version (in either directory), try:

> make PYVER=3.3.0

(or whatever version you want).

The executable will be called run-3.3.0.


A 'make dist' in either directory will clean things up again.

#### Testing

There's a script in there to make and run the front-end against the
test suite:

>  python3 ./multitest.py 2.7

This will make and then run the 2.7 front-end against the test cases
in ../testsuite-python-lib for that version.  I haven't copied in the
actual Python libraries in here, so this directory just contains a
simple test file at the moment.  You can list multiple front-ends here
and it will produce a latex-able table of the results.


#### Menhir modules

In the menhir case, the parsers sub-directory contains 45 grammar
fragments ("modules").  To get the modules for a particular version,
use the file name; for example

> ls parsers/*_3.3.0_*.mly

gives you the 7 modules used in the front-end for Python 3.3.  The
Makefile just combines these with ebnfmacros.mly (the definitions for
the EBNF operators that we use) and then feeds the lot into menhir.


### Authors are:
* [Brian A. Malloy](http://www.brianmalloy.com/), Clemson University, SC, USA
* [James F. Power](http://www.cs.nuim.ie/~jpower/), Maynooth University, Ireland


