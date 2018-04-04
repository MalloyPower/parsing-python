@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}

module pygrat::extract::Extracters

// A common interface for reading EBNF, Bison and BGF grammar files.

import Prelude;

import pygrat::MyGrammar;

import grammarlab::io::read::BGF;

import pygrat::misc::Util;
import pygrat::extract::PyEBNF2BGF;
import pygrat::extract::Bison2BGF;
import pygrat::extract::Menhir2BGF;

// Just cass the relevant converter based on the given file suffix
public GGrammar extractGrammar(loc gramfile)
{
	str suffix = gramfile.extension;
	if (suffix == BISON_GRAMMAR_SUFFIX)
		return pygrat::extract::Bison2BGF::extractG(gramfile);
	if (suffix == MENHIR_GRAMMAR_SUFFIX)
		return pygrat::extract::Menhir2BGF::extractG(gramfile);
	else if (suffix == BGF_GRAMMAR_SUFFIX) {
		GGrammar bgf = grammarlab::io::read::BGF::readBGF(gramfile);
		return tidyGrammar(bgf);
	}
	else  { // Assume it's a Python EBNF file
		GGrammar pyg = pygrat::extract::PyEBNF2BGF::extractG(gramfile);
		return preparePythonGrammar(pyg);
	}
} 


