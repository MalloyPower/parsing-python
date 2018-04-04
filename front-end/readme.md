### Multiple front-ends for Python

The code in this directory builds the running front-ends for Python.

- bison-front-end: you'll need a system with gcc, flex and bison
- menhir-front-end: you'll need a system with ocaml, ocamllex and menhir

This uses the generated conflict-free parsers as well as
version-specific scanners in the scanners/ subdirectory.

To build a front-end (in either directory), try:

> make PYVER=3.3.0

(or whatever version you want).

A 'make dist' in either directory will clean things up again.


There's a script in there to make and run the fron-end against the
test suite:

>  python3 ./multitest.py 2.7

This will make and then run the 2.7 front-end against the testcases in
../testsuite-python-lib.  I haven't copied in the actual Python
libraries in here, so this directory just contains a simple file at
the moment.  You can list multiple front-ends here and it will produce
a latex-able table of the results.

You can see the parsers and scanners in the relevant subdirectories.
In the menhir case, the parsers subdirectory contains 45 grammar
fragments ("modules").  To get the modules for a version, use the file
name; for example parsers/*_3.3.0_*.mly gives you the 7 modules used
in the front-end for Python 3.3.

### Authors are:
* [Brian A. Malloy](http://www.brianmalloy.com/), Clemson University, SC, USA
* [James F. Power](http://www.cs.nuim.ie/~jpower/), Maynooth University, Ireland


