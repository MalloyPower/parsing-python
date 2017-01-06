@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pyparse::Bisonify
/* 
 * Take a GGrammar object and put it into a format suitable for Bison.
 * In particular, eliminate all star, plus, optional and (embedded) choice operators.
 */


import Prelude;
import util::Maybe;

import grammarlab::export::Grammar; // ppx
import grammarlab::transform::Normal; // normalise

import pyparse::MyGrammar;
import pyparse::RuleDuplicates;
import pyparse::misc::SiteSpecific;
import pyparse::misc::Util;
import pyparse::extract::Extracters;
import pyparse::extract::Gram2Bison;  
import pyparse::extract::Bison2BGF;  // Want to be able to extract raw production rules for hints

// Prefixes for the new non-terminals that get generated:
private set[str] GEN_NONT_NAMES = {"opt", "star", "plus", "pick"};

// Supply a list of suggested names for new non-ts:
private str NAME_HINT_FILE = "name-hints" + BISON_GAMMAR_DOT_SUFFIX;

// Replacements I've done, so I don't re-do multiple replacements in the same rule
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
 		case optional(_) : prefix = "opt";
 		case star(_) : prefix = "star";
 		case plus(_) : prefix = "plus";
 		case choice(_) : prefix = "pick";
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

// Get the non-Bison constructs in a RHS
private set[GExpr] getNonBison(GExpr expr)
{
	int s = { };
	visit(expr) {
		case optional(expr) : s += optional(expr);
		case star(expr) : s += star(expr);
		case plus(expr) : s += plus(expr);
		case choice(expr) : s += choice(expr);
	}
	if (choice(_) := expr)  // Choice at top-level is OK.
		s -= expr;  
	return s;
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

private void recordDistribute(loc glufile, str lhs) =
	appendToFile(glufile, "distribute in <lhs>.\n");

private void recordComment(loc glufile, str comment, bool nlBefore) =
	appendToFile(glufile, (nlBefore ? "\n" : "") + "<GLUE_COMMENT> <comment>\n");
		
private void recordComment(loc glufile, str comment) =
	recordComment(glufile, comment, false);

// These are the generic replacements we can do (return the new RHS in each case):
private GExpr optRHS(GExpr expr) = choice([expr, epsilon()]);
private GExpr starRHS(str lhs, GExpr expr) = choice([sequence([nonterminal(lhs), expr]), epsilon()]);
private GExpr plusRHS(str lhs, GExpr expr) = choice([sequence([nonterminal(lhs), expr]), expr]);

// The "bisonify" routines: take a RHS, return a new RHS and any extra productions we need.
// Since some refactorings can be optimised at top-level, we have an additional parameter to indicate this (and pass the LHS)

private tuple[GExpr, GProdList] bisonify(str lhs, optional(expr), bool toplevel, loc glufile) 
{
	GExpr oldRHS = optional(expr);
	if (<lhs, oldRHS> in _replacedEarlier)
		return <_replacedEarlier[<lhs, oldRHS>], []>; 
	<bisonExpr, newProdList> = bisonify(lhs, expr, glufile);
	if (toplevel) {
		GExpr newExpr = optRHS(lhs, bisonExpr);
		recordMassage(glufile, lhs, oldRHS, newExpr);
		return noteReplacement(lhs, oldRHS, newExpr, newProdList);
	}
	GExpr tempRHS = optional(bisonExpr);
	str newNont = makeNewNontName(tempRHS);
	GExpr newExpr = nonterminal(newNont);
	GProd newProd = production(newNont, optRHS(bisonExpr));
	newProdList += newProd;
	recordComment(glufile, "replace optional in <lhs> ::= <ppx(tempRHS)>");
	recordExtract(glufile, lhs, tempRHS, newProd);
	recordMassage(glufile, newProd.lhs, tempRHS, newProd.rhs);
	return noteReplacement(lhs, oldRHS, newExpr, newProdList);
}


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

private tuple[GExpr, GProdList] bisonify(str lhs, choice(exprs), bool toplevel, loc glufile) 
{
	GExpr oldRHS = choice(exprs);
	if (<lhs, oldRHS> in _replacedEarlier)
		return <_replacedEarlier[<lhs, oldRHS>], []>; 
	list[GExpr] newExprList = [ ];
	list[GProd] newProdList = [];
	for (e <- exprs) {
		<thisExpr, thisProdList> = bisonify(lhs, e, glufile);
		newExprList += thisExpr;
		newProdList += thisProdList;
	}
	GExpr newRHS = choice(newExprList);
	if (toplevel) // Choice is OK at the top level
		return noteReplacement(lhs, oldRHS, newRHS, newProdList);
	else { // but not if it is embedded in a rule
		str newNont = makeNewNontName(newRHS);
		GExpr newExpr = nonterminal(newNont);
		GProd newProd = production(newNont, newRHS);
		newProdList += newProd;
		recordComment(glufile, "replace embedded choice in <lhs> ::= <ppx(newRHS)>");
		recordExtract(glufile, lhs, newRHS, newProd);
		return noteReplacement(lhs, oldRHS, newExpr, newProdList);
	}
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


// Special case #1: top-level iteration at the end of a RHS can be expanded in-place...
// Note that yaccify in grammarlab is limited to two constucts on the RHS
private bool hasTailIteration([_,star(_)]) = true;
private bool hasTailIteration([_,plus(_)]) = true;
private bool hasTailIteration(list[GExpr] _) = false;

private GExpr expandTailIteration(str lhs, [*E1, star(c)]) =
        choice([sequence(E1), sequence([nonterminal(lhs), c])]);

private GExpr expandTailIteration(str lhs, [*E1, plus(c)]) =
        choice([sequence(E1 + [c]), sequence([nonterminal(lhs), c])]);


// Want to check for nested choices, since 'distribute' will mess these up
private bool hasNestedChoices(GExpr rhs)
{
	visit(rhs) {
		case choice(_) : return true;
	}
	return false;
}

// Special case #2: a single embedded choice operator: just duplicate the RHS for both options 
private bool hasSingleChoice(list[GExpr] exprs) 
{
	bool seenChoice = false;
	for (e <- exprs) {
		switch(e) {
			case choice([c1,c2]) : {
				if (seenChoice || hasNestedChoices(c1) || hasNestedChoices(c2))
					return false;
				seenChoice = true;
			} 
			case choice([_]): return false;  // >2 choices is too complicated
			default: if (hasNestedChoices(e)) return false;
		}
	}
	// If we get here then we didn't find anything to object to
	return seenChoice;
}


private GExpr expandSingleChoice([*E1, choice([c1,c2]), *E2]) =
        choice([sequence(E1 + [c1] + E2), sequence(E1 +[c2] + E2)]);

// Special case #3: a single embedded option operator: just duplicate the RHS for option and epsilon 
private Maybe[GExpr] hasSingleOption(list[GExpr] exprs) 
{
	Maybe[GExpr] seenOption = Maybe::nothing();
	for (e <- exprs) {
		switch(e) {
			case optional(anOpt) : {
				if ((just(_) := seenOption) || hasNestedChoices(anOpt))
					return Maybe::nothing();
				seenOption = just(anOpt);
			} 
			default: if (hasNestedChoices(e)) return Maybe::nothing();
		}
	}
	// If we get here then we didn't find anything to object to
	return seenOption;
}

private GExpr expandSingleOption([*E1, optional(c), *E2]) =
        choice([sequence(E1 +[c] + E2), sequence(E1 + [epsilon()] + E2)]);

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
	else if (hasSingleChoice(exprList)) {
		newRHS = expandSingleChoice(exprList);
		recordComment(glufile, "expand top-level with a single choice in <lhs> ::= <ppx(oldRHS)>");
		recordDistribute(glufile, lhs);
	}
	else if (just(opt) := hasSingleOption(exprList)) {
		newRHS = expandSingleOption(exprList);
		recordComment(glufile, "expand top-level with a single option in <lhs> ::= <ppx(oldRHS)>");
		recordMassage(glufile, lhs, optional(opt), optRHS(opt));
		recordDistribute(glufile, lhs);
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
    GGrammar hints = pyparse::extract::Bison2BGF::extractG_raw(hintFile);
    <newg, toReplace> = renumberGeneratedNonts(newg, hints);
	recordBulkRename(newg, toReplace, glufile);
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
		str filestem = replaceLast(infile, PYTHON_GRAMMAR_DOT_SUFFIX, "");
		str outfile = filestem + BISON_GAMMAR_DOT_SUFFIX;
		str glufile = filestem + "-bisonify" + GLUE_FILE_DOT_SUFFIX;
		println("Translating <infile>");
		translateFile(infolder+infile, outfolder+outfile, outfolder+glufile);
	}
}

///////////////////////////////////////
///// Site-specific test routines /////
///////////////////////////////////////

void main() = translateFolder(pyg(), pyg("bisonified-parsers"));

void t() = translateFile(res("test.ebnf"), res("test.y"), res("test-bisonify.glue"));

void f() = translateFile(pyg("2.7.2.txt"), wip("2.7.2-bisonified.y"), wip("2.7.2-bisonify.glue"));
void g() = translateFile(pyg("3.6.0.txt"), genp("3.6.0.y"), genp("3.6.0-bisonify.glue"));



