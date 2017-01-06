@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pyparse::RuleDuplicates

// Code to compare two grammars, looking for similar rules modulo (non-terminal) renaming.

import Prelude;

import pyparse::MyGrammar;
import pyparse::misc::SiteSpecific;
import pyparse::extract::Extracters;

private set[str] GEN_NONT_NAMES = {"opt", "star", "plus", "pick"};
bool isGenNont(str nt) = any(str pre <- GEN_NONT_NAMES, startsWith(nt, pre+"_"));
bool isNumberedNont(str nt) = isGenNont(nt) && (/^[a-z]+_[0-9]+$/ := nt);



// Rename generated non-t's using consecutive numbers
map [str, str] regenNonts(GGrammar g)
{
	str getPrefix(str nt) = substring(nt, 0, findFirst(nt, "_"));
	list[str] generated = [n | production(n,_) <- g.P && isNumberedNont(n)];
	assert size(generated) < 1000 : "Need to pad to more than 3 in the new non-t name";
	map [str, str] toReplace = ();
	for (oldNT <- generated) {
		toReplace[oldNT] = getPrefix(oldNT) + "_" + right("<size(toReplace)+1>", 3, "0");
	}
	return toReplace;
}


// Rename generated non-t's using consecutive numbers
public tuple[GGrammar, ReplacementList] renumberGeneratedNonts(GGrammar g, GGrammar hints)
{
	map [str, str] hintReplace;
	<g, hintReplace> = iteratedEquate(hints, g, true);
	map [str, str] numReplace = regenNonts(g);
	g = bulkReplace(g, numReplace, true);
	return <g, hintReplace+toList(numReplace)>;
}




////////// Eliminate duplicate/cloned rules //////////

// The bisonify algorithm doesn't check if a rule has been generated already (it's much easier this way), 
// so we need a sweep through at the end to eliminate (generated) non-ts with similar RHSs.

// Want to do the replacements in order, so we need a list (and not a map or rel):
public alias ReplacementList = list[tuple[str,str]];


// Do the replacements in the grammar.  This is a lot faster than a series of separate 'equate' operations.
private GGrammar bulkReplace(GGrammar g, map[str,str] toReplace, bool keepInGrammar)
{
	newProds = for (prod <- g.P) { 
		if (prod.lhs in toReplace && !keepInGrammar) continue;
		newRHS = visit(prod.rhs) {
			case nonterminal(n) => nonterminal(n in toReplace ? toReplace[n] : n)
		}
		str newLHS = ((prod.lhs in toReplace) ? toReplace[prod.lhs] : prod.lhs);
		append production(newLHS, newRHS);
	}
	list[str] remainingN = [n | production(n,_) <- newProds];
	return grammar(remainingN, newProds, g.S);
}


// Anonymise recursive references in the RHS so they don't interfere with matching:
private GExpr anonRec(str lhs, GExpr rhs)
{
	str ANON_REC = "__self__";  // Can use anything here that's not already a non-t
	return visit(rhs) {
		case nonterminal(n) => nonterminal(lhs == n ? ANON_REC : n)
	}
}

// 'Reverse' a grammar, to give a map from RHS to LHSs:
private map[GExpr, list[str]] makeRhsIndex(GProdList prodList)
{
	map[GExpr, list[str]] rhsIndex = ();
	for (prod <- prodList)  
	{
		GExpr anonRhs = anonRec(prod.lhs, prod.rhs);
		if (anonRhs in rhsIndex) 
			rhsIndex[anonRhs] += [prod.lhs];
		else 
			rhsIndex[anonRhs] = [prod.lhs];
	}
	return rhsIndex;
}


///// Look for duplicates in one grammar /////

// Find non-ts whose RHSs are the same and equate them; just one pass through the grammar.
// Return a map of the replacements (order doesn't matter in one pass).
private map[str,str] onePassEquate(GGrammar g)
{
	// First make a map of RHS -> LHS-list for any generated non-ts
	GProdList getNontProds = [p | GProd p <- g.P, isGenNont(p.lhs)];
	map[GExpr, list[str]] rhsIndex = makeRhsIndex(getNontProds);
	// Now get any replacements from multiply-defined RHSs in rhsIndex
	map [str, str] toReplace = ();
	for (ntList <- range(rhsIndex), size(ntList)>1) 
	{
		str nOrig = ntList[0];   // Keep the non-t that was declared first
		for (nClone <- ntList[1..]) {
			toReplace[nClone] = nOrig; 
		}
	}
	return toReplace;
}


// Repeatedly pass through the grammar, equating non-ts with similar RHSs, until nothing changes (fixpoint)
public tuple[GGrammar, ReplacementList] iteratedEquate(GGrammar g)
{
	ReplacementList rl = [ ];
	bool changedSomething = true;
	while (changedSomething) {
		map [str, str] toReplace = onePassEquate(g);
		changedSomething = ! isEmpty(toReplace);
		if (changedSomething) {
			g = bulkReplace(g, toReplace, false);
			rl += toList(toReplace);
		}
	}
	return <g, rl>;
}



///// Look for duplicates between *two* grammars 
///// In these routines, the goal is to change the *second* grammar so it aligns with the first

// One pass through the second grammar, looking for non-ts with similar RHSs to the first
// Return a map of the replacements (order doesn't matter in one pass).
// Considers all non-ts.  No rules in the first grammar are changed.
private map[str,str] onePassEquate(GGrammar g1, GGrammar g2)
{
	// First make a map of RHS -> LHS-list for all non-ts in the first grammar
	map[GExpr, list[str]] rhsIndex = makeRhsIndex(g1.P);
	// Now go through the second grammar looking for matching RHSs but different LHSs
	map [str, str] toReplace = ();
	for (prod <- g2.P)  { // all nont-ts in the second grammar
		GExpr anonRhs = anonRec(prod.lhs, prod.rhs);
		if (anonRhs in rhsIndex && !(prod.lhs in rhsIndex[anonRhs])) {
			// Make sure you don't rename to a non-t that's already in g2:
			list[str] replacements = [n | str n <- rhsIndex[anonRhs], n notin g2.N];  
			if (! isEmpty(replacements)) {
				str g1Orig = replacements[0]; // Pick the non-t in g1 that was declared first
				toReplace[prod.lhs] = g1Orig; // Maps g2 non-t to the corresponding g1 non-t
			}
		}
	}
	return toReplace;
}


// Repeatedly pass through the second grammar, looking for non-ts with similar RHSs to the first
// Keep iterating until nothing more changes; return the replacements and the (modified) second grammar.
public tuple[GGrammar, ReplacementList] iteratedEquate(GGrammar g1, GGrammar g2, bool keepInGrammar)
{
	ReplacementList rl = [ ];
	bool changedSomething = true;
	while (changedSomething) {
		map [str, str] toReplace = onePassEquate(g1, g2);
		changedSomething = ! isEmpty(toReplace);
		if (changedSomething) {
			g2 = bulkReplace(g2, toReplace, keepInGrammar);   // N.B. Changing second grammar only
			rl += toList(toReplace);
		}
	}
	return <g2, rl>;
}

public tuple[GGrammar, ReplacementList] iteratedEquate(GGrammar g1, GGrammar g2) = iteratedEquate(g1, g2, false);

///////////////////////////////////////
///// Site-specific test routines /////
///////////////////////////////////////

void compareTwoParsers(loc yFile1, loc yFile2)
{
	//writeFile(diffFile, "// Diff <yFile1.file> vs. <yFile2.file>; generated on <today()>\n");
	println("Parsing <yFile1>");
	GGrammar g1 = extractGrammar(yFile1);
	println("Parsing <yFile2>");
	GGrammar g2 = extractGrammar(yFile2);
	<g2, toReplace> = iteratedEquate(g1, g2);
	for (<oldNT, newNT> <- toReplace)
		println("equate <oldNT> with <newNT>.");
}

loc parser(str f) = cwd("work-in-progress") + f;

void ct() = compareTwoParsers(parser("2.7.2.y"), parser("parse.y"));

