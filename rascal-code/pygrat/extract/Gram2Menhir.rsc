@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pygrat::extract::Gram2Menhir

/* 
 * Take a GGrammar object and write it in a format suitable for Menhir.
 */


import Prelude;
import util::Maybe;

import pygrat::MyGrammar;
import pygrat::misc::SiteSpecific;
import pygrat::misc::Util;
import pygrat::extract::Extracters;


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
private str strMenhir(optional(GExpr expr)) = "_optional(<strMenhir(expr)> {})";
private str strMenhir(star(GExpr expr)) = "_star(<strMenhir(expr)> {})";
private str strMenhir(plus(GExpr expr)) = "_plus(<strMenhir(expr)> {})";
private str strMenhir(sepliststar(GExpr expr, GExpr sep)) 
	= "separated_list(<strMenhir(sep)>, <strMenhir(expr)> {})";
private str strMenhir(seplistplus(GExpr expr, GExpr sep)) 
	= "separated_nonempty_list(<strMenhir(sep)>, <strMenhir(expr)> {})";

private str strMenhir(choice(GExprList exprs)) // Internal choice
{
	list[str] csStr = [strMenhir(c) | c <- exprs];
	return "_choice(<intercalate(" | ", csStr)> {})";
}

private str strMenhir(choice(csList), true) // Top-level choice
{
	list[str] csStr = [((epsilon():=c) ? "// empty" : strMenhir(c)) | c <- csList];
	return intercalate("\n\t| ", csStr);
}

private str strMenhir(GExpr rhs, bool _) = strMenhir(rhs);

private str strMenhir(GExpr rhs) = "\<unknown\>";


// The boilerplate code at the top of the file
private str menhirPrefix() =
	intercalate("\n", [
	"%{",

	"%}",
	""]);

// The boilerplate code at the bottom of the file
private str menhirSuffix() =
	intercalate("\n", [
	""]);

// Definition of rule templates:
private str menhirDefs() =
	intercalate("\n", [
	"%inline _optional(X):",
	"  /* nothing */ {}",
	"| X {}",
	";",
	"",
	"%inline _choice(X):",
	"  X {}",
	";",
    "",
	"_star(X):",
    "  /* nothing */ {}",
    "| _star(X) X  {}",
    ";",
    "",
    "_plus(X):",
    "  X {}",
    "| _plus(X) X {}",
    ";",
	""]);

public list[str] menhirPrelude(GGrammar g)
{
	list[str] res = [ ];
	res += menhirPrefix();
	res += getTokenDecls(g);
	res += ["", "%start \<unit\> " + intercalate(" ", g.S), ""];
	return res;
}

// Print a grammar as a menhir .mly file 
list[str] strMenhir(GGrammar g) = strMenhir(g, just(g.S), true, false);
list[str] strMenhir(GGrammar g,  bool wantPrelude, bool declarePublic)
{
	map[str,list[str]] usedBy = xref(g);
	list[str] res = [ ];
	if (wantPrelude)
		res += menhirPrelude(g);
	else if (size(g.S)>1)
		res += ["", "// Top non-terminals: " + intercalate(" ", sort(g.S)), ""];
	res += ["", "%%", ""];
	for (GProd p <- g.P) {
		str thisLine = "<p.lhs>:";
		if (declarePublic)
			thisLine = "%public\n" + thisLine;
		if (p.lhs in usedBy)
			thisLine += " // Used in: <intercalate(", ", usedBy[p.lhs])>";
		thisLine += "\n\t  ";
		thisLine += strMenhir(p.rhs, true);
		thisLine += "\n\t{} ;\n";
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
		str filestem = replaceLast(infile, dot(PYTHON_GRAMMAR_SUFFIX), "");
		str outfile = filestem + dot(MENHIR_GRAMMAR_SUFFIX);
		println("Translating <infile>");
		translateFile(infolder+infile, outfolder+outfile);
	}
}



///////////////////////////////////////
///// Site-specific test routines /////
///////////////////////////////////////

void main() = translateFolder(pyg(), wip()+"menhir"+"original");

void trf(str ver) = translateFile(pyg(ver+dot(PYTHON_GRAMMAR_SUFFIX)), wip(ver+dot(MENHIR_GRAMMAR_SUFFIX)));

void f() = trf("2.7.2");
void g() = trf("3.6.0.");

