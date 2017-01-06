@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pyparse::extract::Gram2Menhir

/* 
 * Take a GGrammar object and write it in a format suitable for Menhir.
 */


import Prelude;
import util::Maybe;

import pyparse::MyGrammar;
import pyparse::misc::SiteSpecific;
import pyparse::misc::Util;
import pyparse::extract::Extracters;


////////// Printing routines //////////

// The %token declarations at the start of the file (same as bison)
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

private str strMenhir(epsilon()) = "/* empty */";
private str strMenhir(nonterminal(str n)) = n;
private str strMenhir(terminal(str t)) = t;
private str strMenhir(sequence(GExprList exprs)) = intercalate(" ", [strMenhir(e) | e <- exprs]);
private str strMenhir(optional(GExpr expr)) = "option(<strMenhir(expr)> {})";
private str strMenhir(star(GExpr expr)) = "list(<strMenhir(expr)> {})";
private str strMenhir(plus(GExpr expr)) = "nonempty_list(<strMenhir(expr)> {})";
private str strMenhir(sepliststar(GExpr expr, GExpr sep)) 
	= "separated_list(<strMenhir(sep)>, <strMenhir(expr)> {})";
private str strMenhir(seplistplus(GExpr expr, GExpr sep)) 
	= "separated_nonempty_list(<strMenhir(sep)>, <strMenhir(expr)> {})";

private str strMenhir(choice(GExprList exprs)) // Internal choice
{
	list[str] csStr = [strMenhir(c) | c <- exprs];
	return "anonymous(<intercalate(" | ", csStr)> {})";
}

private str strMenhir(choice(csList), true) // Top-level choice
{
	list[str] csStr = [((epsilon():=c) ? "// empty" : strMenhir(c)) | c <- csList];
	return intercalate("\n\t| ", csStr);
}

private str strMenhir(GExpr rhs, bool _) = strMenhir(rhs);

private str strMenhir(GExpr rhs) = "\<unknown\>";


// The boilerplate C code at the top of the file
private str menhirPrefix() =
	intercalate("\n", [
	"%{",

	"%}",
	""]);

// The boilerplate C code at the bottom of the file
private str menhirSuffix() =
	intercalate("\n", [
	""]);

// Print a grammar as a Bison .y file (assumes it has already been bison-ified)
list[str] strMenhir(GGrammar g)
{
	map[str,list[str]] usedBy = xref(g);
	list[str] res = [ ];
	res += menhirPrefix();
	res += getTokenDecls(g);
	res += ["", "%start \<int\>" + intercalate(" ",g.S), ""];
	res += ["", "%%", ""];
	for (GProd p <- g.P) {
		str thisLine = "<p.lhs>";
		if (p.lhs in usedBy)
			thisLine += " // Used in: <intercalate(", ", usedBy[p.lhs])>";
		thisLine += "\n\t: ";
		thisLine += strMenhir(p.rhs, true);
		thisLine += "\n\t{} ;";
		res += thisLine;
	}
	res += ["", "%%", ""];
	res += menhirSuffix();
	return res;
}


void translateFile(loc infile, loc outfile)
{
	GGrammar pyg = extractGrammar(infile);
	writeFile(outfile, "// Converted from <infile.file> on <today()>\n\n");
	appendToFile(outfile, ["<s>\n" | s <- strMenhir(pyg)]);
}

public void translateFolder(loc infolder, loc outfolder)
{
	assert isDirectory(infolder) : "<infolder> is not a directory";
	assert isDirectory(outfolder) : "<outfolder> is not a directory";
	for (str infile <- getPythonGrammarFiles(infolder))
	{
		str filestem = replaceLast(infile, PYTHON_GRAMMAR_DOT_SUFFIX, "");
		str outfile = filestem + MENHIR_GAMMAR_DOT_SUFFIX;
		println("Translating <infile>");
		translateFile(infolder+infile, outfolder+outfile);
	}
}



///////////////////////////////////////
///// Site-specific test routines /////
///////////////////////////////////////

void main() = translateFolder(pyg(), wip());

void trf(str ver) = translateFile(pyg(ver+PYTHON_GRAMMAR_DOT_SUFFIX), wip(ver+MENHIR_GAMMAR_DOT_SUFFIX));

void f() = trf("2.7.2");
void g() = trf("3.6.0.");

