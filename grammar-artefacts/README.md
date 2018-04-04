# Grammar Artefacts

This directory holds the various artefacts used in getting from the
distributed Python EBNF to menhir and bison parsers.  We include this
so that our experiments can be reproduced.

## Starting point: the EBNF Python grammars.

These were downloaded from python.org and extracted from the source.
We have divided this into two directories based on differences.  This almost corresponds to major and minor versions so we have:

01-ebnf-major-versions: grammars that differed from their predecessor
02-ebnf-minor-versions: grammars the same a their predecessor

We don't consider any of the grammars from the 02-ebnf-minor-versions
directory any further here.

Actually, the folder 01-ebnf-major-versions also contains three
grammars that have non-relevant modifications from their predecessor:
2.3, 2.4.3, 2.7.2.  The mofiications we may when converting these to
parsers will eliminate those differences, so they are not considered
further in the paper.

The 01-ebnf-major-versions directory also contains a subdiretory with
EBNFs for Python series 1, but we have not done anything further with
these.


## Transforming EBNF to menhir parsers

The handwritten XBGF to do this is in the directory 03-handwritten-xbgf.

This code, when run, transforms the EBNF in the 01-ebnf-major-versions
directory to the menhir-compatible parsers in the
04-conflictfree-menhir directory.

When you run any of the .mly files in 04-conflictfree-menhir through
menhir they should generate a parser without reporting any conflicts.


## Transforming menhir parsers to bison parsers.

The EBNF constructs used in the menhir parsers can be transformed
out to get a standard context-free grammar.  Since these are standard
transformations, we have generated the XBGF transformations to do
this, and stored them in the directory 05-generated-xbgf.

That is, when the transformations in 05-generated-xbgf are run, they
transform the menhir parsers of 04-conflictfree-menhir to the bison
parsers in 06-conflictfree-bison.

When you run any of the .y files in 06-conflictfree-bison through
bison they should generate a parser without reporting any conflicts.


### References:
* [menhir](http://gallium.inria.fr/~fpottier/menhir/),
a LR(1) parser generator for the OCaml.
* [bison](https://www.gnu.org/software/bison/manual/),
the yacc-compatible parser generator.
* [XBGF](https://github.com/grammarware/slps/wiki/XBGF),
an operator suite for programmable manipulation of grammars.
* [Rascal](http://www.rascal-mpl.org/) a language for
"metaprogramming": analysing, transforming or generating source code.



### Authors are:
* [Brian A. Malloy](http://www.brianmalloy.com/), Clemson University, SC, USA
* [James F. Power](http://www.cs.nuim.ie/~jpower/), Maynooth University, Ireland
