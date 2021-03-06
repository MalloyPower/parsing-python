@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pygrat::extract::PyEBNF2BGF
/*
 * Parser for the EBNF that Python grammar files seem to use.
 * options use [x], repetition is x* and x+
 * This was originally generated by PyBNF.rsc, but has been manually editied since then.
 */


import String; 
import IO;

import pygrat::MyGrammar;
import pygrat::extract::PyTokens;

import grammarlab::io::Grammar;
import grammarlab::lib::Sizes;

import grammarlab::lib::ebnf::Glue; // GlueEBNF
import grammarlab::export::Grammar; // ppx


syntax PyEBNFGrammar =  PyEBNFLayoutList PyEBNFProduction+ PyEBNFLayoutList;
syntax PyEBNFProduction = PyEBNFNonterminal PyEBNFDefAs {PyEBNFDefinition "|"}+ ;
syntax PyEBNFDefinition = PyEBNFSequence;
syntax PyEBNFSequence = PyEBNFSymbol+;
syntax PyEBNFSymbol
 = nonterminal: PyEBNFNonterminal
 | terminal: PyEBNFTerminal
 | group: "(" {PyEBNFDefinition "|"}+ ")"
 | option: "[" {PyEBNFDefinition "|"}+ "]"
 | star: PyEBNFSymbol "*"
 | plus: PyEBNFSymbol "+";
lexical PyEBNFTerminal 
  = @category="Constant" "\'" PyEBNFSingleQuotedSymbols name "\'" 
  | @category="Constant" "\"" PyEBNFDoubleQuotedSymbols name "\"" 
  | PyEBNFTerminalSymbols name;
lexical PyEBNFSingleQuotedSymbols = ![\']* !>> ![\'];
lexical PyEBNFDoubleQuotedSymbols = ![\"]* !>> ![\"];
lexical PyEBNFNonterminal = @category="Identifier"  PyEBNFNonterminalSymbols name ;
lexical PyEBNFLabel = @category="NonterminalLabel" ![]+ >> [];
lexical PyEBNFMark = @category="NonterminalLabel" ![]* >> [];
lexical PyEBNFDefAs = ":" | "::=" ;
lexical PyEBNFTerminalSymbols = [A-Z]+ !>> [A-Z];
lexical PyEBNFNonterminalSymbols = [a-z_01-9]+ !>> [a-z_01-9];
layout PyEBNFLayoutList = PyEBNFLayout* ;
lexical PyEBNFLayout = [\t-\n\r\ ]* !>> [\t-\n\r\ ] | PyEBNFComment ;
lexical PyEBNFComment = @category="Comment" "#" ![\n]* >>[\n];

//Tree getPyEBNF(str s,loc z) = parse(#PyEBNFGrammar,z);
//public void registerPyEBNF() = registerLanguage("PyEBNF","PyEBNF",getPyEBNF);

private GGrammar mapG((PyEBNFGrammar)`<PyEBNFProduction+ ps>`)
{
	GProdList ps2 = []; 
	list[str] nts = [];
	for(p <- ps) {
		p2 = mapP(p); 
		if(p2.lhs notin nts)
			nts += p2.lhs; 
		ps2 += p2;
	}
	return grammar(nts, ps2, []);
}
private GProdList mapPs(PyEBNFProduction+ ps) = [mapP(p) | p <- ps];
private GProd mapP((PyEBNFProduction)`<PyEBNFNonterminal lhs> <PyEBNFDefAs _> <{PyEBNFDefinition "|"}+ rhds>`) 
  = production("<lhs>",mapDs(rhds));


private GExpr mapDs({PyEBNFDefinition "|"}+ ds)
{
	GExprList es = [mapD(d) | PyEBNFDefinition d <- ds];
	return (len(es)==1) ? es[0] : choice(es);
}
private GExpr mapS((PyEBNFSymbol)`<PyEBNFNonterminal n>`) = nonterminal("<n.name>");
private GExpr mapS((PyEBNFSymbol)`<PyEBNFTerminal t>`) = terminal("<t.name>");
private GExpr mapS((PyEBNFSymbol)`(<{PyEBNFDefinition "|"}+ ds>)`) = mapIDs(ds);
private GExpr mapS((PyEBNFSymbol)`[<{PyEBNFDefinition "|"}+ ds>]`) = optional(mapIDs(ds));
private GExpr mapS((PyEBNFSymbol)`<PyEBNFSymbol smb>*`) = star(mapS(smb));
private GExpr mapS((PyEBNFSymbol)`<PyEBNFSymbol smb>+`) = plus(mapS(smb));
private default GExpr mapS(PyEBNFSymbol smb) {println("Cannot map symbol <smb>!");return empty();}

private GExpr mapIDs({PyEBNFDefinition "|"}+ ds)
{
	GExprList es = [mapD(d) | PyEBNFDefinition d <- ds];
	return (len(es)==1) ? es[0] : choice(es);
}
private GExpr mapD((PyEBNFDefinition)`<PyEBNFSequence d>`) = mapE(d);
private GExpr mapE((PyEBNFSequence)`<PyEBNFSymbol s>`) = mapS(s);
private default GExpr mapE((PyEBNFSequence)`<PyEBNFSymbol+ ss>`) = sequence([mapS(s) | PyEBNFSymbol s <- ss]);


public Tree parsePyEBNF(loc z) = parse(#PyEBNFGrammar, trim(readFile(z))+"\n");

public GGrammar extractG(loc ebnfLoc) = mapG(parsePyEBNF(ebnfLoc));
public GGrammar extractG(str ebnfFile) =  extractG(|cwd:///| + ebnfFile);

public GGrammar preparePythonGrammar(GGrammar pyg)
{
	pyg = tidyGrammar(pyg);
	pyg = augment(pyg);
	pyg = fixTokens(pyg);
	return pyg;
}


public void main(list[str] args)
{
	GGrammar gram = extractG(args[0]);
	if (len(args) > 1) {
		loc outLoc = |cwd:///|+args[1];
		writeBGF(gram, outLoc);
		println("output written to <outLoc>");
	} else {
		println("Result is: <ppx(gram,GlueEBNF)>");
	}
} 


public void main(str arg) { main([arg]); }
