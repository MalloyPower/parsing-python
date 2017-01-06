@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}

module extract::PyBNF
/*
 * OBSOLETE: Do not use.
 * This file generated the parser for Python EBNF files, sort of.
 * Based on hacking the module grammarlab::lib::ebnf::Default
 */
 
import IO;
import grammarlab::language::EBNF;
import grammarlab::extract::EBNF2Rascal;

public EBNF PyEBNF = (
	defining_symbol(): " : ",
	terminator_symbol(): "\n",
	definition_separator_symbol(): " : ",
	disjunction_symbol(): " | ",
	concatenate_symbol(): " ",
	start_comment_symbol(): "#",
	end_comment_symbol(): "\n",
	start_group_symbol(): "(",
	end_group_symbol(): ")",
	start_terminal_symbol(): "\\\'",
	end_terminal_symbol(): "\\\'",
	start_option_symbol(): "[",
	end_option_symbol(): "]",
	postfix_repetition_star_symbol(): "*",
	postfix_repetition_plus_symbol(): "+"
);


public void old_main()
{
	str filePrefix = "PyEBNFParser";    // The filename/module to be written
	loc rsc = |project://Test/src/|+(filePrefix+".rsc");  // Write in current project
	println("Writing Rascal code to <rsc>...");
	assert ! isFile(rsc) : "Fail: I won\'t overwrite an existing file!";
	str rascalCode = EDD2Rascal(PyEBNF, filePrefix);
	writeFile(rsc, rascalCode);
	println("Done.");
	// println(EDD2Rascal(PyEBNF,"PyEBNF"));
}

public void main() {
	assert false : "Run once to generate file.  Do not run again.";
}
