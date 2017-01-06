@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pyparse::CalcMetrics

// Calculate the metrics from our Software Maintenance and Evolution 2004 paper.
// Corrected from that paper: tree impurity, McCabe

import Prelude;
import util::Math;  // for log2

import pyparse::MyGrammar;
import pyparse::misc::Util;
import pyparse::misc::SiteSpecific;

import pyparse::extract::Extracters;


//////////////////////////////////////////
////////// Grammar size metrics //////////
//////////////////////////////////////////


// Size: the number of *uses* of terminals and non-terminals on the RHSs (return total & avg)
tuple[int, real] calcSize(GGrammar g)
{
	int tot = 0;
	for (prod <- g.P) {
		visit(prod.rhs) {
			case terminal(str _): { tot += 1; }
			case nonterminal(str _): { tot += 1; }
		}
	}
  	return <tot, toReal(tot)/size(g.P)>;
}

// McCabe for a RHS: sum the number of "decisions" on the RHSs, plus one.
// I think we forgot the "plus one" part in our original paper.
int calcMcCabe(GExpr rhs)
{
	int numDecisions = 0;
	visit(rhs) {
		case choice(GExprList exprs): { numDecisions += size(exprs)-1; }
		case optional(GExpr expr)	: { numDecisions += 1; }
		case star(GExpr expr): { numDecisions += 1; }	
		case plus(GExpr expr)	: { numDecisions += 1; }
		case sepliststar(GExpr expr, GExpr sep)	: { numDecisions += 1; }		// zero-or-more separator list
		case seplistplus(GExpr expr, GExpr sep)	: { numDecisions += 1; }		// one-or-more separator list
	}
  	return numDecisions + 1;
}

// McCabe for a grammar: sum the complexity of each grammar rule
int calcMcCabe(GGrammar g) = sum([calcMcCabe(rhs) | production(_,rhs) <- g.P]);


// Halstead: Total number of *uses* of operators and operands
tuple[int, int] opCount(GGrammar g) 
{
	int operatorCount = 0;
	int operandCount = 0;
	for (prod <- g.P) {
		operandCount += 1;   // For the non-terminal occurrence on the LHS.
		visit(prod.rhs) {
			// Two kinds of operand:
			case terminal(str _): { operandCount += 1; }
			case nonterminal(str _): { operandCount += 1; }
			// Eight kinds of operators (last two not used so far):
			case choice(GExprList exprs): { operatorCount += size(exprs)-1; }
			case sequence(GExprList exprs): { operatorCount += size(exprs)-1; }
			case star(GExpr expr): { operatorCount += 1; }	
			case plus(GExpr expr)	: { operatorCount += 1; }
			case optional(GExpr expr)	: { operatorCount += 1; }
			case epsilon() :  { operatorCount += 1; }
			case sepliststar(GExpr expr, GExpr sep)	: { operatorCount += 1; }		// zero-or-more separator list
			case seplistplus(GExpr expr, GExpr sep)	: { operatorCount += 1; }		// one-or-more separator list
		}
	}
	return <operatorCount, operandCount>;
}

// Halstead: Number of *distinct* operators and operands
tuple[int, int] opDistinct(GGrammar g) 
{
	set[str] operators = {"choice", "sequence", "star", "plus", "optional", "epsilon"};
	set[str] operands = (calcTerminals(g) + calcNonTerminals(g));
	return <size(operators), size(operands)>;
}


// Halstead: calculation of effort metric 
// Taken from https://en.wikipedia.org/wiki/Halstead_complexity_measures
real calcHalstead(GGrammar g)
{
	<eta1, eta2> = opDistinct(g);
 	assert eta2 > 0 : "distinct operands <eta2> must be non-zero";   // or div-by-zero later
	<n1, n2> = opCount(g);
 	real volume = (n1 + n2) * log2(eta1+eta2);
 	real difficulty = (eta1 / 2.0) * (toReal(n2) / eta2);
 	real effort = difficulty * volume;
 	return effort;
}



/////////////////////////////////////////////////
////////// Grammar equivalence classes //////////
/////////////////////////////////////////////////

alias EquivClass = set[str];   // A set of non-terminals, actually


rel[str,str] calcDerivesInOne(GGrammar g)
{
	rel[str,str] derives = {};
	for (prod <- g.P) {
		visit(prod.rhs) {
			case nonterminal(str nont): { derives += <prod.lhs, nont>; }
		}
	}
	return derives; 
}

// Calculate the set of equivalence classes, given the derives relation
// One pass through the grammar, check each non-t for membership of existing classes.
set[EquivClass] calcEquivClasses(GGrammar g, rel[str,str] derivesInMany)
{
    bool similar(str nt1, str nt2) = (nt1 in derivesInMany[nt2]) && (nt2 in derivesInMany[nt1]) ;
	map[int, EquivClass] classes = ( );
  	// For each declared non-terminal, put it in the correct equivalence class:
	for (prod <- g.P) {
		// See if lhs belongs in an existing equivalence class:
		bool foundClass = false;
		for (idx <- classes) {
			// Compare lhs with any element of the equiv class
			str anElement = getOneFrom(classes[idx]);
			if (similar(prod.lhs, anElement)) {
				classes[idx] += prod.lhs;
				foundClass = true;
				break;
			}
		}
		if (! foundClass) { // Not there, so make a new class for it
			EquivClass newClass = {prod.lhs};
			classes[size(classes)] = newClass;
		}
	}
	return range(classes);
}

// Defunct: thought I could use Racal's 'group' function... 
set[EquivClass] old_calcEquivClasses(GGrammar g, rel[str,str] derivesInMany)
{
    bool similar(str nt1, str nt2) = (nt1 in derivesInMany[nt2]) && (nt2 in derivesInMany[nt1]) ;
    set[str] declNonts = domain(g.productions);
	return group(declNonts, similar);
}
 
// Just pretty-print some details about the equiv classes
str displayEquivClasses(GGrammar g,  set[EquivClass] classes)
{
	list[str] res = [];
	set[EquivClass] nonSingleton = {s | EquivClass s <- classes, size(s)>1};
	res += "There are <size(classes)> equivalence classes, "
		+  "of which <size(nonSingleton)> are non-singleton:";
	for (c <- nonSingleton) res += "\t<size(c)>: <c>";
	real equivPercent =  round(size(classes) * 100.0 / size(calcNonTerminals(g)), .01);
	res += "As a percentage of the number of non-terminals, there are <equivPercent>% equivalence classes";
	int largestSize = max({size(s) |  EquivClass s <- classes}); 
	res += "(Depth) Largest equivalence class has <largestSize> non-terminals";
	return intercalate("\n", res);
}


// We originally coded the impurity metric as:
real calcWrongImpurity(int n, int edgeCount) = (100.0 * (edgeCount - n + 1)) / ((n-1)*(n-1));
// Our bad! This metric was corrected in the grammarlab code to:
real calcRightImpurity(int n, int edgeCount) = (100.0 * (edgeCount - n + 1)) / (n*(n-1));
// See: https://github.com/grammarware/slps/blob/master/shared/python/metrics.py

real calcImpurity(int n, rel[str,str] derives) = (n>1) ? calcRightImpurity(n, size(derives)) : 0.0;


// Basically the idea is to start with the roots, add in any equiv. class that has a derives-in-one relationship.
// Iterate this until done.  The height is the number of iterations.
// Kind of like a breadth-first search.
tuple[int,real] calcVarjuHeight(list[str] roots, rel[str,str] derivesInOne,  set[EquivClass] classes)
{
	set[str] doing = toSet(roots);
	set[EquivClass] todo = {s | EquivClass s <- classes};  // Work-list: make a copy of the set of equiv classes
	int heightTot = 0;
	while (! isEmpty(doing)) {
		set[str] newDoing = { };
		set[EquivClass] newTodo = { };
		// Place each class from todo into one of: newDoing or newTodo
		for (EquivClass cls <- todo) {
			bool addThisClass = any(str t <- cls, any(str d <- doing, (t == d) || t in derivesInOne[d]));  // Inefficient, but pretty
			if (addThisClass)
				newDoing += cls;   // Reachable: so add the contents (non-ts)
			else
				newTodo += {cls};  // Not reachable, so add the class (as a unit) to the new work-list
		}
		// Now I've collected a new set of non-ts, so shuffle everyone along...
		doing = newDoing;
		todo = newTodo;
		heightTot += 1;
	}
	real heightPer = (toReal(heightTot) * 100.0 / size(classes)); 
	return <heightTot, heightPer>;
}



/////////////////////////////////////////
///// Printing routines for metrics /////
/////////////////////////////////////////


str displayLevels(GGrammar g, bool printDerives)
{
	list[str] res = [];
	rel[str,str] derivesInOne = calcDerivesInOne(g);
	res += "The derives-in-one relation has <size(derivesInOne)> tuples";
	if (printDerives) {
		res += "<derivesInOne>";
	}
	rel[str,str] derivesInMany = derivesInOne*;
	res += "The derives-in-many relation has <size(derivesInMany)> tuples";
	int ntCount = size(calcNonTerminals(g));
	res += "Fenton impurity is: <round(calcImpurity(ntCount, derivesInOne),.01)>";
	res += "Fenton closed impurity is: <round(calcImpurity(ntCount, derivesInMany),.01)>";
	set[EquivClass] classes = calcEquivClasses(g, derivesInMany);
	res += displayEquivClasses(g, classes);
	<heightTot, heightPer> = calcVarjuHeight(g.S, derivesInOne, classes);
	res += "Varju height metric is <heightTot>, which is <round(heightPer,.01)>% of the <size(classes)> equivalence classes.";
	return intercalate("\n", res);
}


// The abbreviated one-line version with all the metrics:
str oneLineMetrics(GGrammar g, str sep)
{
	str mStr(str m) = "<sep><right(m, 5, " ")>";
	str mStr(num m) = mStr("<m>");
	str gramStr = "";
	// Non-terminals:
	int ntCount = size(calcNonTerminals(g));
	gramStr += mStr(ntCount) + mStr(size(recalcTopNonterminals(g))) + mStr(size(recalcBotNonterminals(g)));
	// Terminals:
	gramStr += mStr(size(calcTerminals(g)));
	// Size metrics for variable-usage on RHS:
	<totSize, avgSize> = calcSize(g);
	gramStr += mStr(totSize) + mStr(round(avgSize,.01));
	// Traditional metrics:
	gramStr += mStr(calcMcCabe(g)) + mStr(round(calcHalstead(g),1));
	// (Fenton) Tree impurity
	rel[str,str] derivesInOne = calcDerivesInOne(g);
	rel[str,str] derivesInMany = derivesInOne*;
	gramStr += mStr(round(calcImpurity(ntCount, derivesInOne),.01));
	gramStr += mStr(round(calcImpurity(ntCount, derivesInMany),.01));
	// Grammar levels (equivalence classes)
	set[EquivClass] classes = calcEquivClasses(g, derivesInMany);
	set[EquivClass] nonSingleton = {s | EquivClass s <- classes, size(s)>1};
	gramStr += mStr(size(classes)) + mStr(size(nonSingleton));
	real equivPercent =  round(size(classes) * 100.0 / ntCount,0.1);
	int largestSize = max({size(s) |  EquivClass s <- classes}); 
	gramStr += mStr(equivPercent) + mStr(largestSize);
	// Varju height
	<heightTot, heightPer> = calcVarjuHeight(g.S, derivesInOne, classes);
	gramStr += mStr(heightTot) + mStr(round(heightPer, .01));
	return gramStr;
}

str oneLineMetrics(GGrammar g) = oneLineMetrics(g, CSV_SEP);

// The long-winded version:
str detailedMetrics(GGrammar g)
{
  list[str] res = [];
  res += toString(g, false);
  <totSize, avgSize> = calcSize(g);
  res += "Total Size = <totSize>; average size = <round(avgSize,.01)>";
  res += "McCabe complexity = <calcMcCabe(g)>";
  res += "Halstead volume = <round(calcHalstead(g))>";
  res += displayLevels(g, false);
  res += "";
  return intercalate("\n", res);
}


void processFile(loc base, str yfile, loc outfile)
{
	GGrammar gg = extractGrammar(base+yfile);
	println("<delExt(base,yfile)><oneLineMetrics(gg)>");
	if (! isFile(outfile))
		writeFile(outfile, "Generated on: <today()>\n");
	appendToFile(outfile, "############### <yfile> ###############\n");
	appendToFile(outfile, detailedMetrics(gg));
}

void processFolder(loc base, loc outfile)
{
	assert isDirectory(base) : "<base> is not a directory";
	list[str] files = getPythonGrammarFiles(base);
	println("Writing to <outfile>");
	writeFile(outfile, "Generated on: <today()>\n");
	for (yfile <- files) 
		processFile(base, yfile, outfile);
}

void processNonPythonFolder(loc base, loc outfile)
{
	assert isDirectory(base) : "<base> is not a directory";
	list[str] files = getAnyGrammarFiles(base);
	println("Writing to <outfile>");
	writeFile(outfile, "Generated on: <today()>\n");
	for (yfile <- files) 
		processFile(base, yfile, outfile);
}


///////////////////////////////////////
///// Site-specific test routines /////
///////////////////////////////////////

public void synQ(loc outfile) = processNonPythonFolder(cwd("SynQ/grammars/standards/"), outfile);
public void synQ() = synQ(res("lang-metrics-details.txt"));

// Calculate the metrics for Ralf's Java grammars
public void java() 
{
	loc javaFolder = cwd("java-grammars/extracted");
	loc outfile = res("java-ex-metrics.txt");
	// Make sure we get these in the right order:
	list[str] javaGrammars = ["java-<k>-<v><BGF_GAMMAR_DOT_SUFFIX>" | v <- [1,2,3], k <- ["impl", "read"]];
	println("Writing to <outfile>");
	writeFile(outfile, "Generated on: <today()>\n");
	for (str javaFile <- javaGrammars) {
		processFile(javaFolder, javaFile, outfile);
	}
}


public void csharp() {
	processFile(cwd("csharp"), "temp-csharp.y", res("csharp-metrics.txt"));
}

public void pyth() = processFolder(cwd("python-grammars"), res("python-metrics.txt"));


public void x() = processFile(res(), "test2.ebnf", res("test2-metrics.txt"));



