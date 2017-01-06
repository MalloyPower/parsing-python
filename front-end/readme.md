### A front-end for Python

The code in this directory builds a running front-end for Python;
you'll need a system with gcc, flex and bison for it to compile.

It uses the generated conflict-free parsers as well as
version-specific scanners in the scanners/ subdirectory.

Just running `make` should build a parser for the latest version in
series 2 and series 3, called pyparse-2.7.2 and pyparse-3.6.0
respectively.  Running `make all` gets you all 15 front-ends.

In case anything goes wrong with the Makefile, doing the build 
process by hand is very simple: just flex the scanner, bison the 
parser, and compile everything together with main.c.

As you can see from main.cpp,  when running the executable 
you can either supply the name of a file to parse, or else use standard input.


### Authors are:
* [Brian A. Malloy](http://www.brianmalloy.com/), Clemson University, SC, USA
* [James F. Power](http://www.cs.nuim.ie/~jpower/), Maynooth University, Ireland


