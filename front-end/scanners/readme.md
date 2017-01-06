### Scanners for Python

These are flex-based scanners for Python, one for each version in
series 2 and 3.  Actually, there's really only one scanner for each
series (orig-scan-v2.l and orig-scan-v3.l) and the others are minor
variations of these.  In fact, there's really only one scanner
(period), as the main differences between v2 and v3 are some new
keywords, and a re-working of the definitions for numeric and
character literals in v3.  If you look in the Makefile you can see the
edits we used to get from the two original scanners to the ones for each
of the individual versions.

We wrote this with one eye on the (hand-written) scanner code in the
[source for the CPython distribution](https://www.python.org/downloads/source/) (if you unzip the source, the relevant files are Parser/tokenizer.[hc]).
We've tried to keep the names of our variables consistent with this, in case
you've read it.  If not it doesn't matter too much, as things are
pretty simple in our scanner anyway.

The main issue with a Python scanner is the indentation: the parser is
set up to expect a DEDENT token when the indentation level is reduced.
This is a little awkward, since one NEWLINE in the scanner means that
we potentially have to send several DEDENT tokens to the parser before
the NEWLINE.  This is achieved using a counter for pending
indents/dedents, as well as a single-token buffer.  There's some minor
fiddling to do with the interaction between this and EOFs, line
continuations, multi-line string-comments etc., but nothing major.

Our v2 scanner has a dodgy hack to allow v3 print statements if it
sees "print_function".  We should really check to see that this is
part of an import declaration, but we wanted to keep the thing as
lightweight as possible.  This hack allowed a bunch of test-cases
through that might otherwise have failed, and that had some interesting
constructs that we wanted to test.



### Authors are:
* [Brian A. Malloy](http://www.brianmalloy.com/), Clemson University, SC, USA
* [James F. Power](http://www.cs.nuim.ie/~jpower/), Maynooth University, Ireland


