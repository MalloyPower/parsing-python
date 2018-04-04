@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pygrat::Bisonify
/* 
 * Take a GGrammar object and put it into a format suitable for Bison.
 * In particular, eliminate all star and plus operators, expand optional. 
 * To parallel menhir's approach, leave choice operators alone, but 'distribute' at end.
 */


import Prelude;
import util::Maybe;

import grammarlab::export::Grammar; // ppx
import grammarlab::transform::Normal; // normalise

import pygrat::MyGrammar;
import pygrat::RuleDuplicates;
import pygrat::misc::SiteSpecific;
import pygrat::misc::Util;
import pygrat::extract::Extracters;
import pygrat::extract::Gram2Bison;  
import pygrat::extract::Bison2BGF;  // Want to be able to extract raw production rules for hints

// Prefixes for the new non-terminals that get generated:
private set[str] GEN_NONT_NAMES = {"opt", "star", "plus", "pick"};

// Supply a list of suggested names for new non-ts:
private str NAME_HINT_FILE = "name-hints" + dot(BISON_GRAMMAR_SUFFIX);

// Replacements I've done, so I don't re-do multiple replacements in the *same rule*.
// Indexed by the non-t on the LHS and the replaced expr; return the replacement expr
private map[tuple[str, GExpr], GExpr] _replacedEarlier = ();  

// All new non-t's that I've invented so far (so I don't use the names a second time)
private set[str] _newNames =  { };   


private void init()
{
	_replacedEarlier = ();
	_newNames = { };
}

////////// Utility routines //////////

// Get all the terminals and (non-generated) non-terminals used in a RHS.
private list[str] extractSymbols(GExpr expr)
{
	list[str] res = [];
	visit(expr) {
		case nonterminal(n) : res += n;
		case terminal(t) : res += t;
	}
	// Filter out the generated ones:
	return [r | r <- res, r notin _newNames];
}

// Generate a new non-terminal; try and make a meaningful name, otherwise just use a number.
private str makeNewNontName(GExpr expr) 
{
 	str prefix = "unknown";
 	switch (expr) {
 		case optional(_) : /*prefix = "opt";*/  assert false : "Not extracting options any more";
 		case star(_) : prefix = "star";
 		case plus(_) : prefix = "plus";
 		case choice(_) : /*prefix = "pick";*/  assert false : "Not extracting choices any more";
 	}
	str nont = "";
	// First try and make a meaningful name based on one or two of the symbols we're replacing:
	list[str]symbs = extractSymbols(expr);
	switch(symbs) {
		case [sym] : nont = "<prefix>_<sym>";
		case [sym1,sym2] : nont = "<prefix>_<sym1>_<sym2>";
	}
	if (size(nont) == 0 || nont in _newNames) {  // OK, just use a number instead
	  	nontCount = size(_newNames);
 		nont = "<prefix>_<nontCount>";
 	}
	_newNames += nont;
	return nont;
}


private tuple[GExpr, GProdList] noteReplacement(str lhs, GExpr oldExpr, GExpr newExpr, GProdList newProds)
{
	_replacedEarlier[<lhs, oldExpr>] = newExpr;
	return <newExpr, newProds>;
}

////////// Refactoring routines //////////
private str GLUE_COMMENT = "//";
private str pRule(str lhs, GExpr rhs) = "<lhs> ::= <ppx(rhs)>;";

private void recordBulkEquate(ReplacementList toReplace, loc glufile)
{
	if (isEmpty(toReplace))
		return;
	recordComment(glufile, "Phase 2:", true);
	recordComment(glufile, "Equating <size(toReplace)> cloned non-terminals:");
	for (<oldNT, newNT> <- toReplace)
		appendToFile(glufile, "equate <oldNT> with <newNT>.\n");
}

private void recordBulkRename(GGrammar g, ReplacementList toReplace, loc glufile)
{
	if (isEmpty(toReplace))
		return;
	recordComment(glufile, "Phase 3:", true);
	recordComment(glufile, "Renaming <size(toReplace)> generated non-terminals:");
	//toReplace = sort(toReplace, bool(<_,a>,<_,b>) { return a<b; });
	for (<oldNT, newNT> <- toReplace) {
		appendToFile(glufile, "rename <oldNT> to <newNT> globally. ");
		recordComment(glufile, "RHS is <ppx(getFirstProduction(g, newNT))>");
	}
}

private void recordMassage(loc glufile, str lhs, GExpr oldExpr, GExpr newExpr) = 
	appendToFile(glufile, "massage <ppx(oldExpr)> to (<ppx(newExpr)>) in <lhs>.\n");

private void recordYaccify(loc glufile, str lhs, GExpr oldExpr, GExpr newExpr) = 
	appendToFile(glufile, "yaccify <pRule(lhs,newExpr)>. <GLUE_COMMENT> replaces <ppx(oldExpr)>\n");
	
private void recordExtract(loc glufile, str lhs, GExpr oldExpr, GProd newProd) =
	appendToFile(glufile, "extract <pRule(newProd.lhs, oldExpr)> in <lhs>.\n");

private void recordInline(loc glufile, str lhs) =
	appendToFile(glufile, "inline <lhs>.\n");

private void recordDistribute(loc glufile, str lhs) =
	appendToFile(glufile, "distribute in <lhs>.\n");

private void recordGlobalDistrbute(loc glufile) =
	appendToFile(glufile, "distribute globally.\n");

private void recordComment(loc glufile, str comment, bool nlBefore) =
	appendToFile(glufile, (nlBefore ? "\n" : "") + "<GLUE_COMMENT> <comment>\n");
		
private void recordComment(loc glufile, str comment) =
	recordComment(glufile, comment, false);

// These are the generic replacements we can do (return the new RHS in each case):
// We're assuming the EBNF operator applies to the *whole* RHS.
private GExpr optRHS(GExpr expr) = choice([expr, epsilon()]);
private GExpr starRHS(str lhs, GExpr expr) = choice([sequence([nonterminal(lhs), expr]), epsilon()]);
private GExpr plusRHS(str lhs, GExpr expr) = choice([sequence([nonterminal(lhs), expr]), expr]);

// The "bisonify" routines: 
// take a (part of a) RHS, return a replacement RHS and any extra productions we need.
// Since some refactorings can be optimised at top-level, 
// we have an additional parameter to indicate this (and thus also pass the LHS)
// The LHS is the LHS of the whole rule, even if expr is just a part of the RHS.

// Replace e? with (e | ε) 
private tuple[GExpr, GProdList] bisonify(str lhs, optional(expr), bool toplevel, loc glufile) 
{
	GExpr oldRHS = optional(expr);
	if (<lhs, oldRHS> in _replacedEarlier)
		return <_replacedEarlier[<lhs, oldRHS>], []>; 
	<bisonExpr, newProdList> = bisonify(lhs, expr, glufile);
	GExpr newExpr = optRHS(bisonExpr);
	recordMassage(glufile, lhs, optional(bisonExpr), newExpr);
	return noteReplacement(lhs, oldRHS, newExpr, newProdList);
}

// Replace e* with star_e, where star_e ::= star_e e | ε
private tuple[GExpr, GProdList] bisonify(str lhs, star(expr), bool toplevel, loc glufile) 
{
	GExpr oldRHS = star(expr);
	if (<lhs, oldRHS> in _replacedEarlier)
		return <_replacedEarlier[<lhs, oldRHS>], []>; 
	<bisonExpr, newProdList> = bisonify(lhs, expr, glufile);
	if (toplevel) {
		GExpr newExpr = starRHS(lhs, bisonExpr);
		recordYaccify(glufile, lhs, star(bisonExpr), newExpr);
		return noteReplacement(lhs, oldRHS, newExpr, newProdList);
	}
	GExpr tempRHS = star(bisonExpr);
	str newNont = makeNewNontName(tempRHS);
	GExpr newExpr = nonterminal(newNont);
	GProd newProd = production(newNont, starRHS(newNont, bisonExpr));
	newProdList += newProd;
	recordComment(glufile, "replace star in <lhs> ::= <ppx(tempRHS)>");
	recordExtract(glufile, lhs, tempRHS, newProd);
	recordYaccify(glufile, newProd.lhs, tempRHS, newProd.rhs);
	return noteReplacement(lhs, oldRHS, newExpr, newProdList);
}

// Replace e+ with plus_e, where plus_e ::= plus_e e | e
private tuple[GExpr, GProdList] bisonify(str lhs, plus(expr), bool toplevel, loc glufile) 
{
	GExpr oldRHS = plus(expr);
	if (<lhs, oldRHS> in _replacedEarlier)
		return <_replacedEarlier[<lhs, oldRHS>], []>; 
	<bisonExpr, newProdList> = bisonify(lhs, expr, glufile);
	if (toplevel) {
		GExpr newExpr = plusRHS(lhs, bisonExpr);
		recordYaccify(glufile, lhs, plus(bisonExpr), newExpr);
		return noteReplacement(lhs, oldRHS, newExpr, newProdList);
	}
	GExpr tempRHS = plus(bisonExpr);
	str newNont = makeNewNontName(tempRHS);
	GExpr newExpr = nonterminal(newNont);
	GProd newProd = production(newNont, plusRHS(newNont, bisonExpr));
	newProdList += newProd;
	recordComment(glufile, "replace plus in <lhs> ::= <ppx(tempRHS)>");
	recordExtract(glufile, lhs, tempRHS, newProd);
	recordYaccify(glufile, newProd.lhs, tempRHS, newProd.rhs);
	return noteReplacement(lhs, oldRHS, newExpr, newProdList);
}

// Leave choice alone
private tuple[GExpr, GProdList] bisonify(str lhs, choice(exprs), bool toplevel, loc glufile) 
{
	GExpr oldRHS = choice(exprs);
	// bisonify the individual elements of the choice and stick them back together...
	list[GExpr] newExprList = [ ];
	list[GProd] newProdList = [];
	for (e <- exprs) {
		<thisExpr, thisProdList> = bisonify(lhs, e, glufile);
		newExprList += thisExpr;
		newProdList += thisProdList;
	}
	GExpr newRHS = choice(newExprList);
	return <newRHS, newProdList>;
}

private tuple[GExpr, GProdList] bisonify(str lhs, sequence(exprs), bool toplevel, loc glufile) 
{
	GExpr oldRHS = sequence(exprs);
	if (<lhs, oldRHS> in _replacedEarlier)
		return <_replacedEarlier[<lhs, oldRHS>], []>; 
	if (toplevel) {	// Handle some special cases:
		GExpr newRHS = toplevelSpecialCases(lhs, oldRHS, glufile);
		if (! newRHS := oldRHS) {  // Changed, so we're not a sequence any more...
			return bisonify(lhs, newRHS, true, glufile);
		}
	}
	// So, bisonify the individual elements of the sequence and stick them back together...
	list[GExpr] newExprList = [];
	list[GProd] newProdList = [];
	for (e <- exprs) {
		<thisExpr, thisProdList> = bisonify(lhs, e, glufile);
		newExprList += thisExpr;
		newProdList += thisProdList;
	}
	GExpr newRHS = sequence(newExprList);  // This is the new sequence
	return noteReplacement(lhs, oldRHS, newRHS, newProdList);
}

// Default: atomic RHS => change nothing:
private tuple[GExpr, GProdList] bisonify(str _, GExpr otherRHS, bool _, loc _) = <otherRHS, []>;

// Default: not in toplevel unless told otherwise:
private tuple[GExpr, GProdList] bisonify(str lhs, GExpr e, loc glufile) = bisonify(lhs, e, false, glufile);


// Special case: top-level iteration at the end of a RHS can be expanded in-place...
// Note that yaccify in grammarlab is limited to two constucts on the RHS
private bool hasTailIteration([_,star(_)]) = true;
private bool hasTailIteration([_,plus(_)]) = true;
private bool hasTailIteration(list[GExpr] _) = false;

private GExpr expandTailIteration(str lhs, [*E1, star(c)]) =
        choice([sequence(E1), sequence([nonterminal(lhs), c])]);

private GExpr expandTailIteration(str lhs, [*E1, plus(c)]) =
        choice([sequence(E1 + [c]), sequence([nonterminal(lhs), c])]);

// If we're at the top-level we can be more optimal in some of our replacements:
private GExpr toplevelSpecialCases(str lhs, sequence(exprList), loc glufile) 
{
	GExpr oldRHS = sequence(exprList);  
	GExpr newRHS = oldRHS;    // Default if no change is possible
	if (hasTailIteration(exprList)) {
		newRHS = expandTailIteration(lhs, exprList);
		recordComment(glufile, "expand top-level tail iteration in <lhs> ::= <ppx(oldRHS)>");
		recordYaccify(glufile, lhs, oldRHS, newRHS);
	}
	return newRHS;
}


// Main entry point: apply the bisonify transformations to a whole grammar:
GGrammar bisonify(GGrammar g, loc glufile)
{
	init();
	set[str] newNonts = toSet(g.N);
	GProdList newRules = [ ];
	for (GProd p <- g.P) 
	{
		<newRhs, newProdList> = bisonify(p.lhs, p.rhs, true, glufile);
		newNonts += {s | production(s,_) <- newProdList};
		newRules += [production(p.lhs, newRhs)];
		newRules +=  newProdList;
	}
	return grammar(toList(newNonts), normalise(newRules), g.S);
}

///// End of "bisonify" routines.

// Not used at the moment...
void inline_choices(GGrammar pyg, loc glufile)
{
	recordComment(glufile, "Phase 4:", true);
	recordComment(glufile, "Inlining generated non-terminals for opt/pick:");
	for (str nont <- pyg.N) {
		if ((startsWith(nont, "opt_") || startsWith(nont, "pick_"))) {
			recordInline(glufile, nont);
		} 
	}
	recordGlobalDistrbute(glufile);
}


void translateFile(loc infile, loc outfile, loc glufile)
{
	GGrammar pyg = extractGrammar(infile);
	writeFile(glufile, "");  // Create the empty file
	recordComment(glufile, "Automatically generated from <infile.file> on <today()>");
	recordComment(glufile, "Transformations to convert (bisonify) <infile.file> to <outfile.file>\n");
	GGrammar newg = bisonify(pyg, glufile);
	// Now sort out any duplicate non-terminals:
	<newg, toReplace> = iteratedEquate(newg);
	recordBulkEquate(toReplace, glufile);
	// Make sure we have the best possible names for the generated non-terminals:
	loc hintFile = glufile.parent + NAME_HINT_FILE;
	assert isFile(hintFile) : "Error locating hint file <hintFile>";
    GGrammar hints = pygrat::extract::Bison2BGF::extractG_raw(hintFile);
    <newg, toReplace> = renumberGeneratedNonts(newg, hints);
	recordBulkRename(newg, toReplace, glufile);
	inline_choices(newg, glufile);
	recordComment(glufile, "The generated bisonify transformations end here.\n", true);
	// Lastly, write the bison file:
	writeFile(outfile, "// Generated (bisonified) from <infile.file> on <today()>\n\n");
	appendToFile(outfile, ["<s>\n" | s <- strBison(newg)]);
}

public void translateFolder(loc infolder, loc outfolder)
{
	assert isDirectory(infolder) : "<infolder> is not a directory";
	assert isDirectory(outfolder) : "<outfolder> is not a directory";
	for (str infile <- getPythonGrammarFiles(infolder))
	{
		str filestem = replaceLast(infile, dot(PYTHON_GRAMMAR_SUFFIX), "");
		str outfile = filestem + dot(BISON_GRAMMAR_SUFFIX);
		str glufile = filestem + "-bisonify" + dot(GLUE_FILE_SUFFIX);
		println("Translating <infile>");
		translateFile(infolder+infile, outfolder+outfile, outfolder+glufile);
	}
}

///////////////////////////////////////
///// Site-specific test routines /////
///////////////////////////////////////

// Translate menhir EBNF files to bisonable .y files.
public void postEBNF()
{
	loc infolder = wip("menhir") + "conflict-free-ebnf";
	loc outfolder = wip("menhir") + "bisonified-parsers";
	loc glufolder = wip("menhir") + "generated-glue";
	for (str infile <- getAnyGrammarFiles(infolder))
	{
		str filestem = replaceLast(infile, dot(MENHIR_GRAMMAR_SUFFIX), "");
		str outfile = filestem + dot(BISON_GRAMMAR_SUFFIX);
		str glufile = filestem + "-bisonify" + dot(GLUE_FILE_SUFFIX);
		println("Translating <infile>");
		translateFile(infolder+infile, outfolder+outfile, glufolder+glufile);
	}
}


