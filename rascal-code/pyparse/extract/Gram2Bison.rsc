@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}

module pyparse::extract::Gram2Bison

import Prelude;
import util::Maybe;

import grammarlab::export::Grammar; // ppx

import pyparse::MyGrammar;

////////// Printing routines //////////

private str intercalate(str sep, list[GExpr] exprs) = intercalate(sep, [strBison(e) | e <- exprs]);

private str strBison(sequence(exprs)) = intercalate(" ", exprs);
private str strBison(nonterminal(n)) = n;
private str strBison(terminal(t)) = t;
private str strBison(epsilon()) = " ";
private str strBison(GExpr e) = "[unknown <ppx(e)>]";

// The %token declarations at the start of the file
private list[str] getTokenDecls(GGrammar g)
{
	int LENGTH_OF_LINE = 70;  // max. number of characters per line
	list[str] tokens = sort(calcTerminals(g));
	list[str] res = ["// <size(tokens)> tokens, in alphabetical order:"];
	str thisLine = "%token";
	for (str t <- tokens) {
		if (size(thisLine) > LENGTH_OF_LINE) {
			res += thisLine;
			thisLine = "%token";
		}
		thisLine += " <t>";
	}
	return res + thisLine;
}

// The boilerplate C code at the top of the file
private str bison_C_Prefix() =
	intercalate("\n", [
	"%{",
	"\tint yylex (void);",
	"\textern int yylineno;",
	"\textern char *yytext;",
	"\tvoid yyerror (char const *);",
	"%}",
	""]);

// The boilerplate C code at the bottom of the file
private str bison_C_Suffix() =
	intercalate("\n", [
	"#include \<stdio.h\>",
	"void yyerror (char const *s)",
	"{",
	"\tfprintf (stderr, \"%d: %s with [%s]\\n\", yylineno, s, yytext);",
	"}",
	""]);

// Print a grammar as a Bison .y file
public list[str] strBison(GGrammar g)
{
	map[str,list[str]] usedBy = xref(g);
	list[str] res = [ ];
	res += bison_C_Prefix();
	res += getTokenDecls(g);
        res += ["", "%locations", ""];
	res += ["", "%start " + intercalate(" ",g.S), ""];
	res += ["", "%%", ""];
	for (GProd p <- g.P) {
		str thisLine = "<p.lhs>";
		if (p.lhs in usedBy)
			thisLine += " // Used in: <intercalate(", ", usedBy[p.lhs])>";
		thisLine += "\n\t: ";
		switch(p.rhs) {
			case choice(csList) : {
				list[str] csStr = [((epsilon():=c) ? "%empty" : strBison(c)) | c <- csList];
				thisLine += intercalate("\n\t| ", csStr);
			}
			default : thisLine += strBison(p.rhs);
		}
		thisLine += "\n\t;";
		res += thisLine;
	}
	res += ["", "%%", ""];
	res += bison_C_Suffix();
	return res;
}


