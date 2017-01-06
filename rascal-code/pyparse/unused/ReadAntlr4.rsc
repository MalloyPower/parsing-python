module extract::ReadAntlr4

// This was an attempt to parse Antrl4 grammars using the grammarlab parser
// ... but that seems to be ambiguous, which screws everything up.
// I disambiguated it by hacking things away, but it's still too much work.

import Prelude;
import util::Maybe;
import Ambiguity;


import MyGrammar;
import extract::ANTLR4;
import misc::SiteSpecific;
import misc::Util;

GGrammar exGram((ANTLR4Grammar)`<GrammarType g><Id n> ; <PrequelConstruct* pc>	<RuleSpec* rs> <ModeSpec* ms>`)
{
	println("Grammar is called: <n>");
	GProdList gps = [];
	visit (rs) {
		case RuleSpec r : exRule(r);
	}
	return grammar([], gps, []);
}


GProd exRule((RuleSpec)`<ParserRuleSpec prs>`) = exRule(prs);

GProd exRule((ParserRuleSpec)`<RuleModifier* rm><Id i><ARG_ACTION? a><RuleReturns? r><ThrowsSpec? t><LocalsSpec? l><RulePrequel* rp>:<RuleBlock rb><LexerCommands? lc>;<ExceptionGroup e>`)
{
	str lhs = "<i>";
	println("Got rule for <lhs>");
	GExpr rhs = exRHS(rb);
	return production(lhs, rhs);
}

GExpr exRHS((RuleBlock)`<{LabeledAlt "|"}+ alts>`)
{
	GExprList es = [exAlt(a) | LabeledAlt a <- alts];
	return (len(es)==1) ? es[0] : choice(es);
}

GExpr exAlt((LabeledAlt)`<Alternative a> ("#" Id)?`)
{
	return exAlt(a);
}
GExpr exAlt((Alternative)`<ElementOptions? opts> <Element* els>`)
{
	GExprList es = [exElt(e) | Element e <- els];
	return (len(es)==1) ? es[0] : sequence(es);
}


GGrammar ANTLR4_extractG(loc z)
{
	println("Parsing <z>");
	//ANTLR4Grammar t = parse(#start[ANTLR4Grammar],z).top;
	ANTLR4Grammar t = parse(#ANTLR4Grammar,z);
	if (/amb(_) := t) {
		println("Ambiguity detected: diagnosing...");
		for(msg <- diagnose(t)) {
			switch(msg) {
			case error(str msg, loc at) : println("--- [<at>] ERROR\n<msg>");
			case warning(str msg, loc at) : println("---[<at>] WARNING\n<msg>");
			case info(str msg, loc at): println("---[<at>] INFO\n<msg>");
			}
		}
		assert false : "Parse was ambiguous";
	}
	println("Extracting <z>...");
	return exGram(t);
}

// This is where the .g files are:
loc paloc(str f) = |cwd:///| + "work-in-progress" + "antlr" + f;

// Let's play with an Antlr grammar
void a()
{
	//loc aloc = paloc("jython-grammar/Base.g");
	loc aloc = paloc("Python3-simplified.g4");
	GGrammar g = ANTLR4_extractG(aloc);
	println(MyGrammar::toString(g, true));
}




