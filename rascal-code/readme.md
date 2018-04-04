# The Rascal code

This directory's contents are:

* pyparse/  Our code to do the transforms etc. (written in Rascal)
* rascal-shell-stable.jar  A copy of the Rascal interpreter (from [here](http://update.rascal-mpl.org/console/rascal-shell-stable.jar))  - see [the Rascal download page](http://www.rascal-mpl.org/start/) for more information on this.
* grammarlab/  A copy of Vadim's [GrammarLab code](https://github.com/cwi-swat/grammarlab) (for Rascal) - see [the GrammarLab page](http://grammarware.github.io/lab/index.html) for more on this.
* readme.md This file

Note: Rascal and GrammarLab weren't developed by us, their authors are:
* Rascal: the [CWI SWAT folks](http://www.cwi.nl/research-groups/Software-Analysis-and-Transformation)
* GrammarLab: [Vadim Zaytsev](http://grammarware.github.io/)

No endorsement from these authors is implied etc. etc.


## Running Rascal at the command line:

>  java  -jar  rascal-shell-stable.jar


### "Locations" in Rascal:

To specify file names, folders etc. Rascal uses things called
[locations](http://tutor.rascal-mpl.org/Rascal/Expressions/Values/Location/Location.html),
of type `loc` in the code.  The simplest way to write these is between
vertical bars, and to start from the current directory, so for a file
in the current directory called test.txt we write `|cwd:///test.txt|` -
note no quotes.

### Importing code

Before you use a Rascal module you need to import it.  The module
structure matches the directory structure, and Rascal uses the "::"
notation (like C++). All our code is in pyparse, so the modules you
need to import are here too.  Importing the first module might take a
while as everything gets loaded up, but it should be quicker after
that.


## To calculate grammar metrics:

In the Rascal interpreter, type:

```Rascal
import pygrat::CalcMetrics;
```

To process all the Python grammars in a folder we supply the folder
name and an output file name to a method called `processFolder`.
It's easiest if we define a function to get the right folder first:
```Rascal
loc gf(str f) = |cwd:///../grammar-artefacts| + f; 
```

And then we can run the method to process some grammars (e.g. all the
major versions)

```Rascal
processFolder(gf("01-ebnf-major-versions"), |cwd:///test.txt|)
```

or the generated menhir parsers:

```Rascal
processFolder(gf("04-conflictfree-menhir"), |cwd:///test.txt|)
```

This prints the one-line metric summary on screen, and lists the
details to the file "test.txt".

If you look at the definition of the method on line 299 of the file
pyparse/CalcMetrics.rsc you can see that it just reads the grammar can
calls another method named processFile (defined just above it on line
289).

We can call this method directly to process just one grammar file
(e.g. the original EBNF for ver 2.7.2):

```Rascal
processFile(gf("01-ebnf-major-versions"), "2.7.2.txt", |cwd:///test.txt|)
```

Note the second argument here (the file name) is a string, the other
two are locations.


## To run an XBGF ("glue") transformation

First import the relevant module:

```Rascal
import pygrat::RunTransformation;
```

Let's try transforming some EBNF from python.org to a yacc-able
grammar (but still with conflicts) using the automatically-generated
XBGF.  There are three arguments here: you need to specify the input
file, the glue (XBGF file), and an output file.  I've put them on
separate lines here for clarity:

```Rascal
 runTransforms(
    gf("01-ebnf-major-versions/2.7.txt"), 
    gf("03-handwritten-xbgf/2.7-manual.glue"), 
    |cwd:///test.mly| )
```

When you run this you should see the XBGF commands listed on screen as
they are processed.  It will print the resulting grammar to screen
when it's done (not pretty), but check the output file for a readable
version.  You can run this output (test.y) through bison - for this
example I get 41 shift/reduce, 1 reduce/reduce conflicts.

Similarly, we can try transforming a grammar to eliminate conflicts;
just use a different input and glue file (I could also have used
test.y as the input here).

```Rascal
 runTransforms(
    gf("04-conflictfree-menhir/2.7.mly"), 
    gf("05-generated-xbgf/2.7-bisonify.glue"), 
    |cwd:///test2.y| )
```
As before, the XBGF commands are listed as they're executed, and the
output is in test2.y.  When running this through bison you should get
no conflicts.


### Authors are:
* [Brian A. Malloy](http://www.brianmalloy.com/), Clemson University, SC, USA
* [James F. Power](http://www.cs.nuim.ie/~jpower/), Maynooth University, Ireland


