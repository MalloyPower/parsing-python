@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pyparse::extract::Bison2BGF
/* 
 * Read a Bison .y file and represent it as a GGrammar object.
 * Not the complete implementaiton of .y file format: just enough for the basics.
 */

import IO;
import String; 
import Set;
import pyparse::MyGrammar;


////////// Concrete syntax for Bison .y files //////////

start syntax BisonGrammar =  LAYOUTLIST BisonPrologueDeclaration* "%%" BisonProduction* "%%" CodeAtEnd*;
syntax BisonPrologueDeclaration 
	= BisonDirective BisonDirectiveType? BisonDirectiveSymbol+
	| BisonCodeBlock
	;
syntax BisonDirectiveType = "\<" BisonIdentSymbols tname "\>";
syntax BisonDirectiveSymbol = BisonIdent name | QUOTED_LITERAL name ;
syntax BisonProduction = BisonIdent ":" BisonRhses ";";
syntax BisonRhses 
	= BisonRhs 
	| BisonRhses "|" BisonRhs
	;
syntax BisonRhs = BisonSymbol* ;
syntax BisonSymbol
	= BisonIdent
	| QUOTED_LITERAL
	| "[" BisonRhses "]" 
	| "{" BisonRhses "}" 
	| "(" BisonRhses ")" 
//	| ACTION
	| "%empty"
	| "%prec" BisonIdent
	| "%prec" QUOTED_LITERAL
	;

lexical BisonIdent = @category="Identifier" BisonIdentSymbols name  ;
lexical BisonDirective = "%left" | "%right" | "%nonassoc" | "%start" | "%token" | "%type";
lexical BisonIdentSymbols = [A-Za-z_01-9.]+ !>> [A-Za-z_01-9.];
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
lexical BisonCodeBlock
	= [%][{] BisonCodeBlockBodyToken* [%][}]
	; 
lexical BisonCodeBlockBodyToken 
	= ![%] 
	| PercentOnly
	;
lexical PercentOnly = [%] !>> [}];
// The code at the end of the grammar is just a bunch of lines:
lexical CodeAtEnd 
	= (![\n])* [\ \t\n\r]
	;

////////// Map concrete syntax to GGrammar objects //////////

private GGrammar mapG(bool wantTidy, (BisonGrammar)`<BisonPrologueDeclaration* decls> %% <BisonProduction* ps>  %% <CodeAtEnd* cd>`)
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
	return grammar(gTidy.N, prods, toList(startSymbols));  // ... but insist on the start symbols declared in the bison file
}
private GGrammar mapG(BisonGrammar g) = mapG(true, g);


private tuple[set[str], set[str]] 
mapD((BisonPrologueDeclaration)`<BisonDirective d><BisonDirectiveType? ty><BisonDirectiveSymbol+ ids>`)
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

private tuple[set[str], set[str]] mapD((BisonPrologueDeclaration)`<BisonCodeBlock cb>`) = <{}, {}>;

private GProd mapP((BisonProduction)`<BisonIdent id> : <BisonRhses rs> ;`) = production("<id.name>", choice(mapRs(rs)));

  
private list[GExpr] mapRs((BisonRhses)`<BisonRhs r>`) = [mapR(r)];

private list[GExpr] mapRs((BisonRhses)`<BisonRhses rs> | <BisonRhs r>`) = mapRs(rs) + mapR(r);

private GExpr mapR((BisonRhs)`<BisonSymbol* ss>`) 
{
	//  Just need a little extra manipulation to filter out epsilons()
	list[GExpr] exprs = [mapS(s) | s <- ss];
	exprs = [e | e <- exprs, epsilon() !:= e];
	switch(exprs) {
		case []  : return epsilon();
		case [x] : return x;
		case xs  : return sequence(xs);
	}
}

private GExpr mapS((BisonSymbol)`<BisonIdent id>`) = nonterminal("<id.name>");
private GExpr mapS((BisonSymbol)`<QUOTED_LITERAL s>`) =  terminal("<s.name>");
private GExpr mapS((BisonSymbol)`( <BisonRhses rs> )`) {
	list[GExpr] es = mapRs(rs);
	return (size(es) == 1) ? es[0] : sequence(es);
}
private GExpr mapS((BisonSymbol)`[ <BisonRhses rs> ]`) {
	list[GExpr] es = mapRs(rs);
	return (size(es) == 1) ? optional(es[0]) : optional(sequence(es));
}
private GExpr mapS((BisonSymbol)`{ <BisonRhses rs> }`) {
	list[GExpr] es = mapRs(rs);
	return (size(es) == 1) ? star(es[0]) : star(sequence(es));
}  

private GExpr mapS((BisonSymbol)`%empty`) =  epsilon();

// Ignoring precedence directives:
private GExpr mapS((BisonSymbol)`%prec <BisonIdent id>`) =  epsilon();
private GExpr mapS((BisonSymbol)`%prec <QUOTED_LITERAL ql>`) =  epsilon();

private default GExpr mapS(BisonSymbol s) {println("Cannot map symbol <s>");return epsilon();}


////////// Interface:

// For consistency with the routines in grammarlab::extract::*
public Tree parseBisonGrammar(loc z) = parse(#BisonGrammar, trim(readFile(z))+"\n");
public GGrammar extractG(loc f) = mapG(parseBisonGrammar(f));
public GGrammar extractG_raw(loc f) = mapG(false, parseBisonGrammar(f));
public GGrammar extractG(str ebnfFile) =  extractG(|cwd:///| + ebnfFile);

void main(list[str] inFileList)
{
	for (str inFile <- inFileList) {
		if (isFile(|cwd:///|+inFile)) {
			str outFile = replaceLast(inFile, ".y", ".txt");
			GGrammar g = extractG(|cwd:///|+inFile);
			writeFile(|cwd:///|+outFile, toString(g,true));
		}
		else {
			println("Error - cannot open file <inFile>");
		}
	}
}

void main() = main(["data/ansic.y"]);


