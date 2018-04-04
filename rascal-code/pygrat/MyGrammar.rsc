@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pygrat::MyGrammar
/*
 * Some extra utility routines for manipulating GGrammar objects.
 */


import Prelude;

extend grammarlab::language::Grammar;
import grammarlab::export::Grammar; // ppx

// So I can remember this:
// data GGrammar = grammar(list[str] N, GProdList P, list[str] S)


// Routines to re-calculate top and bottom non-terminals from scratch.
// N.B. These don't iterate (this isn't 'productive' and 'reachable' non-terminals...)

tuple[set[str],set[str]] recalcDefUseNonTerminals(GGrammar g) 
{
	set[str] definedNonterminals = { };
	set[str] usedNonterminals = { };
	for (GProd p <- g.P) {
		definedNonterminals += p.lhs;
		visit(p.rhs) {
			case nonterminal(str n): { usedNonterminals += n; }
		}
	}
	return <definedNonterminals, usedNonterminals>;
}	

// Top non-terminals: defined (i.e. on LHS) but not used on any RHS:
set[str] recalcTopNonterminals(GGrammar g) 
{
	<definedNonterminals, usedNonterminals> = recalcDefUseNonTerminals(g);
	return definedNonterminals - usedNonterminals;
}	
// Bottom non-terminals: used (on some RHS) but not declared:
set[str] recalcBotNonterminals(GGrammar g) 
{
	<definedNonterminals, usedNonterminals> = recalcDefUseNonTerminals(g);
	return usedNonterminals - definedNonterminals;
}	

// Get all the non-terminals used or defined in a grammar
set[str] calcNonTerminals(GGrammar g) = toSet(g.N + g.S);
	
// Get all the terminals used in a grammar
set[str] calcTerminals(GGrammar g) 
{
	ts = for (GProd p <- g.P) {
		visit(p.rhs) {
			case terminal(str t): append t;
		}
	}
	return toSet(ts);
}	

// REturn first production for a non-t; exception if there is none.
GExpr getFirstProduction(GGrammar g, str lhs)
{
	for (production(lhs,rhs) <- g.P)
		return rhs;
	assert false : "No production rule found for <lhs>";
}

// Map each terminal/non-terminal to the non-terminal(s) whose definition use it
map[str,list[str]] xref(GGrammar g)
{
	map[str,list[str]] res = ();
	void update(str k, str v) { if (k notin res) res[k] = [v]; else if (v notin res[k]) res[k] += v; } 
	for (GProd p <- g.P) {
		visit(p.rhs) {
			case nonterminal(str n): update(n, p.lhs);
			case terminal(str t): update(t, p.lhs);
		}
	}
	return res;
}	


// Promote embedded choice/sequence to top level
GExpr flatten(choice(GExprList exprs))
{
	GExprList eList = [ ];
	for(GExpr e <- exprs) {
		switch(flatten(e)) {
			case choice(exprs2) : eList += exprs2;
			case other : eList += other;
		}
	}
	return GExpr::choice(eList);
}
GExpr flatten(sequence(GExprList exprs))
{
	GExprList eList = [ ];
	for(GExpr e <- exprs) {
		switch(flatten(e)) {
			case sequence(exprs2) : eList += exprs2;
			case other : eList += other;
		}
	}
	return GExpr::sequence(eList);
}
GExpr flatten(GExpr expr) = expr;


// Merge choices if a rule has >1 production for it.   Kind of like XBGF:horizontal
GExpr mergeChoices(choice(GExprList c1s), choice(GExprList c2s)) = choice(c1s+c2s);
GExpr mergeChoices(choice(GExprList c1s), GExpr c2) = choice(c1s+[c2]);
GExpr mergeChoices(GExpr c1, choice(GExprList c2s)) = choice([c1]+c2s);
GExpr mergeChoices(GExpr c1, GExpr c2) = choice([c1,c2]);


// Tidy up a grammar.  Specifically:
//   Make N be the list of non-terminals actually used on the RHS in the grammar
//   Make P have only one GProd for each non-terminal: use choice to merge.  Flatten RHSs.
//   Add to S all top non-terminals in the grammar (so: disjoint from N)
GGrammar tidyGrammar(GGrammar gg) 
{
	list[str] definedNonterminals = [ ];   // Keep these in the original order
	set[str] usedNonterminals = {};
	set[str] terminals = {};
	map[str, GExpr] prodMap = ();   // Maps non-t to its unique definition.
	for (GProd p <- gg.P) {
		if (p.lhs notin definedNonterminals)
			definedNonterminals += p.lhs;
		// First add this to the map for productions:
		if (p.lhs in prodMap) {
			prodMap[p.lhs] = mergeChoices(prodMap[p.lhs], flatten(p.rhs));
		} else {  // Not there yet
			prodMap[p.lhs] = p.rhs;
		}
		// Next fish out any terminals and non-terminals in RHS
		visit(p.rhs) {
			case nonterminal(str n): { usedNonterminals += n; }
			case terminal(str t): { terminals += t; }
		}
	}
	set[str] newRoots = toSet(gg.S) + (toSet(definedNonterminals) - usedNonterminals);
  	return grammar(toList(usedNonterminals), 
  					[production(lhs, prodMap[lhs]) | str lhs <- definedNonterminals],
  					toList(newRoots));
}
GGrammar tidyGrammar(GProdList prodList) = tidyGrammar(grammar([], prodList, []));


// Return a grammar with a single entry point (start symbol).
// Call me twice to guarantee a unique *production* for the unique start symbol.
// If second parameter is true, then add a new symbol/rule, even if there's only one start symbol anyway.
GGrammar augment(GGrammar g, bool alwaysAugment)
{
	assert !isEmpty(g.S) : "Grammar must have at least one entry point already" ;
	if (size(g.S)==1 && ! alwaysAugment)
		return g;
	// Create a new start symbol: 
	str newStart = "start";
	while (newStart in g.N)  // Make sure it's not already in the grammar
		newStart += "_";
	GExpr newRhs;
	switch(g.S) {  // See if there's one or many existing start symbols
		case {s} : newRhs = nonterminal(s);
		default  : newRhs = choice([nonterminal(s) | str s <- g.S]);
	}
	// Now, augment the grammar with the new production rule:
	return grammar(g.N+g.S, 
					production(newStart, newRhs) + g.P, 
					[newStart]);
}

GGrammar augment(GGrammar g) = augment(g, false);
 
// This is the way I like it printed. 
public str toString(GGrammar g, bool wantProductions) 
{
	str gramStr = "There are <size(g.P)> productions\n";
	if (wantProductions)
		gramStr += ("" | it + e | e <- ["\t<p.lhs> : <ppx(p.rhs)>\n" | p <- g.P]);
	set[str] tops = recalcTopNonterminals(g);	
	gramStr += "There are <size(tops)> top (not used on RHS) nonterminals: <tops>\n";
	set[str] bots = recalcBotNonterminals(g);
	if (size(bots) > 0)
		gramStr += "There are <size(bots)> bottom (undeclared) nonterminals: <bots>\n";
	set[str] terminals = calcTerminals(g);
	gramStr += "There are <size(terminals)> terminals: " + toString(terminals);
	return gramStr;
}

public str toString(GGrammar g) = toSring(g, false);
