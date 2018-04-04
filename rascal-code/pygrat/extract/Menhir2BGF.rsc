@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pygrat::extract::Menhir2BGF
/* 
 * Read a mehir .mly file and represent it as a GGrammar object.
 * Not the complete implementation of .mly file format: just enough for the basics.
 * Note that I use my own names for plus/star etc. - replace these as appropriate.
 */

import IO;
import String; 
import Set;
import pygrat::MyGrammar;
import pygrat::misc::Util;


////////// Concrete syntax for Menhir .y files //////////

start syntax MenhirGrammar =  LAYOUTLIST MenhirPrologueDeclaration* "%%" MenhirProduction* "%%" CodeAtEnd*;
syntax MenhirPrologueDeclaration 
	= MenhirDirective MenhirDirectiveType? MenhirDirectiveSymbol+
	| MenhirCodeBlock
	;
syntax MenhirDirectiveType = "\<" MenhirIdentSymbols tname "\>";
syntax MenhirDirectiveSymbol = MenhirIdent name | QUOTED_LITERAL name ;
syntax MenhirProduction = RuleDirective MenhirIdent Params? ":" MenhirRhses ";";
syntax RuleDirective
    = "%public"
    | "%inline"
    | // Nothing
    ;
syntax Params
    = "(" { MenhirIdent "," }* ")"
    ;
syntax MenhirRhses 
	= MenhirRhs 
	| MenhirRhses "|" MenhirRhs
	;
syntax MenhirRhs = MenhirSymbol* ;
syntax MenhirSymbol
	= MenhirIdent
	| QUOTED_LITERAL
	| "_optional" "(" MenhirRhs ")"
	| "_star" "(" MenhirRhs ")"
	| "_plus" "(" MenhirRhs ")"
	| "_choice" "(" MenhirRhses ")"
// Don't really use the next two, but just in case:	
	| "separated_list" "(" MenhirRhs "," MenhirRhs ")"
	| "separated_nonempty_list" "(" MenhirRhs "," MenhirRhs ")"
// Actions: keep it simple
    | MenhirAction
	| "%prec" MenhirIdent
	| "%prec" QUOTED_LITERAL
	;

lexical MenhirAction = [{] (![}])* [}] ;  // Not very sophisticated (no nesting)
lexical MenhirIdent = @category="Identifier" MenhirIdentSymbols name  ;
lexical MenhirDirective = "%left" | "%right" | "%nonassoc" | "%start" | "%token" | "%type";
lexical MenhirIdentSymbols = [A-Za-z_01-9.]+ !>> [A-Za-z_01-9.];
lexical QUOTED_LITERAL 
	= @category="Constant" [\'] (ESC_SEQ | ![\'\r\n\\])* name [\']
	| @category="Constant" [\"] (ESC_SEQ | ![\"\r\n\\])* name [\"]
	;
lexical ESC_SEQ = [\\][btnfru\"\'\\];
//lexical ACTION = [{] ACTION_EL* [}];
//lexical ACTION_EL = ![}] | ACTION;

// The following is robbed from the C90 grammar, module lang::c90::\syntax::C
lexical Comment 
	= [/][*] MultiLineCommentBodyToken* [*][/] 
	| "//" ![\n]* [\n]
	;
lexical MultiLineCommentBodyToken 
	= ![*] 
	| Asterisk
	;
lexical Asterisk = [*] !>> [/];
layout LAYOUTLIST = LAYOUT* !>> [\ \t\n\r];
lexical LAYOUT 
	= whitespace: [\ \t\n\r] 
	| @category="Comment" comment: Comment
	;
// Code blocks are modelled on the multi-line comments above:
lexical MenhirCodeBlock
	= [%][{] MenhirCodeBlockBodyToken* [%][}]
	; 
lexical MenhirCodeBlockBodyToken 
	= ![%] 
	| PercentOnly
	;
lexical PercentOnly = [%] !>> [}];
// The code at the end of the grammar is just a bunch of lines:
lexical CodeAtEnd 
	= (![\n])* [\ \t\n\r]
	;

////////// Map concrete syntax to GGrammar objects //////////

private GGrammar mapG(bool wantTidy, (MenhirGrammar)`<MenhirPrologueDeclaration* decls> %% <MenhirProduction* ps>  %% <CodeAtEnd* cd>`)
{
	set[str] startSymbols = { };
	set[str] terminals = { };
	for (decl <- decls) {
		<s,t> = mapD(decl);
		startSymbols += s;
		terminals += t;
	}
	GProdList prods = [mapP(p) | p <- ps];
	// If there was no declared start symbol, then use the LHS of the first rule: 
	if (isEmpty(startSymbols)) {
		startSymbols = { prods[0].lhs };
	}
	// Change any mis-identified non-terminals to be terminals:
	prods = for (p <- prods) {
		newRhs = visit(p.rhs) {
			case nonterminal(n) => ((n in terminals) ? terminal(n) : nonterminal(n)) 
		}
		append production(p.lhs, newRhs);
	}
	GGrammar gRaw = grammar([], prods, []); 
	GGrammar gTidy = tidyGrammar(gRaw); // Let tidyGrammar work out the non-ts...
	prods = (wantTidy ? gTidy.P : gRaw.P);
	return grammar(gTidy.N, prods, toList(startSymbols));  // ... but insist on the start symbols declared in the Menhir file
}
private GGrammar mapG(MenhirGrammar g) = mapG(true, g);


private tuple[set[str], set[str]] 
mapD((MenhirPrologueDeclaration)`<MenhirDirective d><MenhirDirectiveType? ty><MenhirDirectiveSymbol+ ids>`)
{
	set[str] startSymbols = { };
 	set[str] terminals = { };
	str directive = "<d>"[1..];
	if  ( directive in ["token", "left", "right", "nonassoc"])
	  terminals += { "<id.name>" | id <- ids };
	else if  (directive in ["start"])
	  startSymbols += { "<id.name>" | id <- ids };
	 return <startSymbols, terminals>;
}

private tuple[set[str], set[str]] mapD((MenhirPrologueDeclaration)`<MenhirCodeBlock cb>`) = <{}, {}>;

private GProd mapP((MenhirProduction)`<RuleDirective rd> <MenhirIdent id> <Params? ps> : <MenhirRhses rs> ;`) 
  = production("<id.name>", choice(mapRs(rs)));

  
private list[GExpr] mapRs((MenhirRhses)`<MenhirRhs r>`) = [mapR(r)];

private list[GExpr] mapRs((MenhirRhses)`<MenhirRhses rs> | <MenhirRhs r>`) = mapRs(rs) + mapR(r);

private GExpr mapR((MenhirRhs)`<MenhirSymbol* ss>`) 
{
	//  Just need a little extra manipulation to filter out epsilons() and tidy:
	list[GExpr] exprs = [mapS(s) | s <- ss];
	exprs = [e | e <- exprs, epsilon() !:= e];
	switch(exprs) {
		case []  : return epsilon();
		case [x] : return x;
		case xs  : return sequence(xs);
	}
}

private GExpr mapS((MenhirSymbol)`<MenhirIdent id>`) = nonterminal("<id.name>");
private GExpr mapS((MenhirSymbol)`<QUOTED_LITERAL s>`) =  terminal("<s.name>");

private GExpr mychoice(list[GExpr] es) = (size(es) == 1) ? es[0] : choice(es);

private GExpr mapS((MenhirSymbol)`_optional ( <MenhirRhs rs> )`) = optional(mapR(rs));

private GExpr mapS((MenhirSymbol)`_star ( <MenhirRhs rs> )`) = star(mapR(rs));
private GExpr mapS((MenhirSymbol)`_plus ( <MenhirRhs rs> )`) = plus(mapR(rs));
private GExpr mapS((MenhirSymbol)`separated_list ( <MenhirRhs elem> , <MenhirRhs sep> )`) 
  = sepliststar(mapR(elem), mapR(sep));

private GExpr mapS((MenhirSymbol)`separated_nonempty_list( <MenhirRhs elem> , <MenhirRhs sep> )`) 
  = seplistplus(mapR(elem), mapR(sep));
  
// anonymous is used for internal choices
private GExpr mapS((MenhirSymbol)`_choice ( <MenhirRhses rs> )`) {
  list[GExpr] exprs = mapRs(rs);
  return (size(exprs) == 1) ? exprs[0] : choice(exprs);
}

// Ignoring precedence directives:
private GExpr mapS((MenhirSymbol)`<MenhirAction act>`) =  epsilon();
private GExpr mapS((MenhirSymbol)`%prec <MenhirIdent id>`) =  epsilon();
private GExpr mapS((MenhirSymbol)`%prec <QUOTED_LITERAL ql>`) =  epsilon();

private default GExpr mapS(MenhirSymbol s) {println("Cannot map symbol [<s>]");return epsilon();}


////////// Interface:

// For consistency with the routines in grammarlab::extract::*
public Tree parseMenhirGrammar(loc z) = parse(#MenhirGrammar, trim(readFile(z))+"\n");
public GGrammar extractG(loc f) = mapG(parseMenhirGrammar(f));
public GGrammar extractG_raw(loc f) = mapG(false, parseMenhirGrammar(f));
public GGrammar extractG(str ebnfFile) =  extractG(|cwd:///| + ebnfFile);

void main(list[str] inFileList)
{
	for (str inFile <- inFileList) {
		if (isFile(|cwd:///|+inFile)) {
			println("Reading menhir grammar from <inFile>");
			GGrammar g = extractG(|cwd:///|+inFile);
			str outFile = replaceLast(inFile, MENHIR_GRAMMAR_SUFFIX, EBNF_GRAMMAR_SUFFIX);
			println("Writing EBNF to <outFile>");
			writeFile(|cwd:///|+outFile, toString(g,true));
		}
		else {
			println("Error - cannot open file <inFile>");
		}
	}
}

void menhirMain() = main(["work-in-progress/menhir/original/2.7.2.mly"]);


