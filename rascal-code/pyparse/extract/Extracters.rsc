@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}

module pyparse::extract::Extracters

// A common interface for reading EBNF, Bison and BGF grammar files.

import Prelude;

import pyparse::MyGrammar;

import grammarlab::io::read::BGF;

import pyparse::misc::Util;
import pyparse::extract::PyEBNF2BGF;
import pyparse::extract::Bison2BGF;

public GGrammar extractGrammar(loc gramfile)
{
	str suffix = gramfile.extension;
	if (suffix == BISON_GAMMAR_SUFFIX)
		return pyparse::extract::Bison2BGF::extractG(gramfile);
	else if (suffix == BGF_GAMMAR_SUFFIX) {
		GGrammar bgf = grammarlab::io::read::BGF::readBGF(gramfile);
		return tidyGrammar(bgf);
	}
	else  { // Assume it's a Python EBNF file
		GGrammar pyg = pyparse::extract::PyEBNF2BGF::extractG(gramfile);
		return preparePythonGrammar(pyg);
	}
} 


