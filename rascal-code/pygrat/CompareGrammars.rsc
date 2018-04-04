@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pygrat::CompareGrammars

// This started out as just some wrappers around grammarlab::compare::Differ

import Prelude;
import util::Maybe;
import util::Math; // for min

import pygrat::MyGrammar;
import pygrat::misc::Util;
import pygrat::misc::SiteSpecific;
import pygrat::extract::Extracters;

import pygrat::extract::Gram2Menhir;

import pygrat::CalcMetrics;

import grammarlab::export::Grammar;  // ppx for RHSs
extend grammarlab::compare::Differ;  // gdt




///////////////////////////////////////////////////////////////////
////////// Comparison routines (adapted from GrammarLab) //////////
///////////////////////////////////////////////////////////////////



// Compare two sets of anything, return summary of differences
private list[str] compareSetsVerbose(str whatAre, set[&X] s1, set[&X] s2) 
{
	list[str] res = [];
	if (s1 == s2) return res;
	set[str] added = s2 - s1;
	set[str] deleted = s1 - s2;
	res += "= Differences in <whatAre> sets: <size(added)> added, <size(deleted)> deleted";
	if (size(deleted) > 0) res += "  - Deleted <size(deleted)>: <deleted>";
	if (size(added) > 0) res += "  + Added <size(added)>: <added>";
	return res;
}
// NB: order is ignored in this lists version (compared as sets):
private list[str] compareSetsVerbose(str whatAre, list[&X] s1, list[&X] s2) = compareSetsVerbose(whatAre, toSet(s1), toSet(s2));


// Verbose grammar compare, made more verbose and adapted to return a string
// Original version was from  grammarlab::compare::Differ
public str gdtv_str(GGrammar g1, GGrammar g2)
{
	list[str] res = [];
	res += compareSetsVerbose("start-symbol", g1.S, g2.S);
	res += compareSetsVerbose("non-terminal", g1.N, g2.N);
	res += compareSetsVerbose("terminal", calcTerminals(g1), calcTerminals(g2));
	<unmatched1,unmatched2> = gdt(g1.P,g2.P);
	res += "Grammar rule differences:\n";
	<ruleAdded, ruleDeleted, ruleChanged> = <0,0,0>;
	for (str nt <- sort(toSet(g1.N + g2.N)))
	{
		rep1 = [p | p:production(nt,_) <- unmatched1];
		rep2 = [p | p:production(nt,_) <- unmatched2];
		if (isEmpty(rep1) && isEmpty(rep2)) continue;
		res += (" * Difference in definition of \'<nt>\':");
		for (p <- rep1) 
			res += ("   - <trim(ppx(p))>");
		for (p <- rep2)
			res += ("   + <trim(ppx(p))>");
		if (!isEmpty(rep1) && isEmpty(rep2)) ruleDeleted += 1;
		if (isEmpty(rep1) && !isEmpty(rep2)) ruleAdded += 1;
		if (!isEmpty(rep1) && !isEmpty(rep2)) ruleChanged += 1;
		res += "";
	}
	res += "= Grammar rule summary: <ruleAdded> added, <ruleDeleted> deleted, <ruleChanged> changed";
	res += "";
    return intercalate("\n", res);
}

// Compare two sets of anything, return size differences
private tuple[int,int] compareSetsNumeric(set[&X] s1, set[&X] s2) = <size(s2 - s1), size(s1 - s2)>;
private tuple[int,int] compareSetsNumeric(list[&X] s1, list[&X] s2) = compareSetsNumeric(toSet(s1), toSet(s2));


// Numeric grammar compare: Nominal differences:
// Return a count of non-ts/terminals added/deleted
public list[int] gramDiffNominal(GGrammar g1, GGrammar g2)
{
	<ntAdded, ntDeleted> = compareSetsNumeric(g1.N, g2.N);
	<tAdded, tDeleted> = compareSetsNumeric(calcTerminals(g1), calcTerminals(g2));
	return [ntAdded, ntDeleted, tAdded, tDeleted];
}

// Numeric grammar compare: Structural differences
// Return a count of rules added/deleted/changed
public list[int] gramDiffStructural(GGrammar g1, GGrammar g2)
{
	<unmatched1,unmatched2> = gdt(g1.P,g2.P);
	// Let's assume one rule per non-terminal:
	set[str] nt1 = {nt | production(nt,_) <- unmatched1};
	set[str] nt2 = {nt | production(nt,_) <- unmatched2};
	<pAdded, pDeleted> = compareSetsNumeric(nt1, nt2);
	int pChanged = size(nt1 & nt2);
	return [pAdded, pDeleted, pChanged];
}


// Nominal and Structural diffs, as per my interpretation of the SQJ 2012 paper (pg. 343) 
public tuple[int, int] gramDiffRalf(GGrammar g1, GGrammar g2)
{
	// Each unmatched non-t counts as a nominal difference:
	set[str] matchedNont = toSet(g1.N) & toSet(g2.N);
	set[str] unMatchedNont = (toSet(g1.N) + toSet(g2.N)) - matchedNont;
	int nominal = size(unMatchedNont);
	<unmatched1,unmatched2> = gdt(g1.P,g2.P);
	int structural = nominal;   // structural is always nominal + ...
	// For evey nominally matched nont, we add the max no of unmatched alternatives (of either grammar)
	for (production(lhs,rhs) <- unmatched1+unmatched2, lhs in matchedNont) {
		structural += calcMcCabe(rhs);  // Using McCabe for "number of alternatives"
	}
	return <nominal, structural>;
}




/////////////////////////////////////////////
////////// Various driver routines //////////
/////////////////////////////////////////////

private int HOWMANY_METRICS = 11;  // 2 Ralf, 4 nominal, 3 structural, 2 totals

// This is the core function that prints a single line of diff metrics
str oneLineDiffs(GGrammar oldPyg, GGrammar newPyg, str sep)
{
	list[int] nominal = gramDiffNominal(oldPyg, newPyg);
	list[int] structural = gramDiffStructural(oldPyg, newPyg);
	<ralfNominal, ralfStructural> = gramDiffRalf(oldPyg, newPyg);
	list[int] metrics = [ralfNominal, ralfStructural] + nominal + sum(nominal) + structural + sum(structural);
	assert size(metrics) == HOWMANY_METRICS;
	return intercalate(sep, metrics);
}
str oneLineDiffs(GGrammar oldPyg, GGrammar newPyg) = oneLineDiffs(oldPyg, newPyg, CSV_SEP);


// Calculate metrics and diffs on a list of grammars 
// Optionally output verbose results to gdtFile: but only if files differ.
public list[str] compareList(loc base, list[str] files, Maybe[loc] gdtFile)
{
	GGrammar oldPyg;
	str lastFileName = "";
	if (just(filename) := gdtFile) {
		println("Writing to <filename>");
		writeFile(filename, "Comparing selected files in <base>; generated on: <today()>\n");
	} 
	outS = for (f <- files)
	{
		println("Working on <base+f>");
		GGrammar pyg = extractGrammar(base+f);
		if ((lastFileName == "") || !gdts(oldPyg, pyg)) { // Not the same as previous grammar 
			if (lastFileName != "" && just(filename) := gdtFile) {
				appendToFile(filename, "\n========== Diff: from <lastFileName> to <f> ==========\n");		
				appendToFile(filename, gdtv_str(oldPyg, pyg));
			}
			append "<rpadFilename(base,f)><oneLineMetrics(pyg)>";
		}
		lastFileName = f;
		oldPyg = pyg;
	}
	return outS;
}


private data DiffData
	= diff(str otherFile, int nominal, int structural);
	

// Compare each grammar in a list with its successors in that list.
// Print out the matches in order (closest first), up to howMany matches.
public void findNearestFactorial(loc base, list[str] files, int howMany)
{
	map[str, list[DiffData]] diffs = ( );
	void recordDiff(str f, DiffData d) { if (f notin diffs) diffs[f] = [d]; else diffs[f] += d; }
	bool ltStruct(DiffData d1, DiffData d2) = d1.structural < d2.structural;
	// First record the diff values:
	for (int i <- [0..size(files)])
	{
		str thisFile = files[i];
		println("Comparing <delExt(base,thisFile)> with <size(files)-(i+1)> others");
		GGrammar thisGram = extractGrammar(base+thisFile);
		// Now compare with all the others following it in the list:
		for (str otherFile <- files[i+1..]) {
			GGrammar otherGram = extractGrammar(base+otherFile);
			<nominal, structural> = gramDiffRalf(thisGram, otherGram);
			recordDiff(thisFile, diff(otherFile, nominal, structural)); // Only record against later versions
			// recordDiff(otherFile, diff(thisFile, nominal, structural));  // for a symmetric relation...  
		}
	}
	// Now print out the best <howMany> diff values:
	for (str file <- files, file in diffs) {
		list[DiffData] mostDiff = sort(diffs[file], ltStruct);
		int toPrint = min(howMany, size(mostDiff));
		msg = for (int i <- [0..toPrint]) {
			append("<delExt(base,mostDiff[i].other)> (<mostDiff[i].structural>)");
		}
		println("<rpadFilename(base,file)>: <intercalate(", ", msg)>");
	}
}

// Compare each grammar in a list with its successors in that list.
// Output a one-line summary of differences to the console.
public void compareListFactorial(loc base, list[str] files)
{
	for (int i <- [0..size(files)])
	{
		str thisFile = files[i];
		GGrammar thisGram = extractGrammar(base+thisFile);
		// Now compare with all the others following it in the list:
		for (str otherFile <- files[i+1..]) {
			GGrammar otherGram = extractGrammar(base+otherFile);
			str msg = "<rpadFilename(base,thisFile)> vs. <rpadFilename(base,otherFile)>";
			println ("<msg><CSV_SEP>" + oneLineDiffs(thisGram, otherGram, CSV_SEP));
		}
	}
}


// Calculate diffs on a list of Python grammars, output one line of diffs per file
// Incremental <=> compare with previous version, otherwise compare all versions with first.
public void quickCompareList(loc base, list[str] files, bool incremental)
{
	GGrammar oldPyg = extractGrammar(base+files[0]);
	println("# Summary diff metrics for <base>, generated on: <today()>");
	// First line: metric-diffs will be all zeros:
	println("<delExt(base,files[0])><CSV_SEP>" + intercalate(CSV_SEP, [0 | _ <- [0..HOWMANY_METRICS]]));
	// Now print everyone else's metric-diffs:
	for (f <- files[1..]) {
		GGrammar newPyg = extractGrammar(base+f);
		println("<delExt(base,f)><CSV_SEP>" + oneLineDiffs(oldPyg, newPyg, CSV_SEP));
		if (incremental)
			oldPyg = newPyg;
	}
}

// Calculate nominal/structual diffs on a list of Python grammars
// Compare all versions with first.
public list[tuple[str,int,int]] quickCompareRalf(loc base, list[str] files)
{
	// First grammar (diffs will be 0):
	GGrammar basePyg = extractGrammar(base+files[0]);
    list[tuple[str,int,int]] results = [ <delExt(base,files[0]), 0, 0>];
	// Now print everyone else's metric-diffs:
	for (f <- files[1..]) {
		GGrammar newPyg = extractGrammar(base+f);
		<nominal, structural> = gramDiffRalf(basePyg, newPyg);
		results += <delExt(base,f), nominal, structural>;
	}
	return results;
}

// Calculate diffs on a folder of Python grammars, output one line of diffs per file
// Incremental <=> compare with previous version, otherwise compare all versions with first.
public void quickCompareFolder(loc base, bool incremental)
{
	assert isDirectory(base) : "<base> is not a directory";
	list[str] files = getPythonGrammarFiles(base);
	quickCompareList(base, files, incremental);
}

// Calculate metrics and diffs on a folder of Python grammars.
// Optionally output verbose results to gdtFile
public list[str] compareFolder(loc base, Maybe[loc] gdtFile)
{
	list[str] files = getPythonGrammarFiles(base);
	return compareList(base, files, gdtFile);
}

public list[str] compareFolder(loc folder) = compareFolder(folder, nothing());

public void compareTwo(loc base, str ver1, str ver2, Maybe[loc] gdtFile) {
	for (s <- compareList(base, [ver1, ver2], gdtFile))
			println(s);	
}

// Diff one grammar against all the other ones
public void compareOneAgainstAll(loc base, str theOne, loc gdtFile)
{
	writeFile(gdtFile, "Comparing version <theOne> with all in <base> on <today()>\n");
	GGrammar gOne = extractGrammar(base + theOne);
	for (str gramFile <- getPythonGrammarFiles(base)) {
		appendToFile(gdtFile, "\n========== Diff from <theOne>  to <gramFile>: ==========\n");	
		GGrammar gOther = extractGrammar(base + gramFile);
		appendToFile(gdtFile, gdtv_str(gOne, gOther));
	}
}

// Diff grammars in the first folder from ones of the same name in the second
public void diffTwoFolders(loc fromCode, loc fromDoc, loc gdtFile) 
{
	writeFile(gdtFile, "Comparing <fromDoc> with <fromCode> on <today()>\n");
	for (str gramFile <- getPythonGrammarFiles(fromDoc)) {
		appendToFile(gdtFile, "\n========== Diff for <gramFile> (from doc to code): ==========\n");	
		GGrammar gDoc = extractGrammar(fromDoc + gramFile);
		GGrammar gCode = extractGrammar(fromCode + gramFile);
		appendToFile(gdtFile, gdtv_str(gDoc, gCode));
	}
}

// As for diffTwoFolders, but print one-line summary of change metrics
public str diffTwoFoldersMetrics(loc fromSource, str srcSuffix, loc fromTarget, str tgtSuffix, str sep) 
{
	list [str] res = [ ];
	for (str srcFile <- sortPyGramByVersion(fromSource, srcSuffix)) {
		str ver =  delExt(fromSource, srcFile);
		str tgtFile = ver + "."+ tgtSuffix;
		if (isFile(fromTarget + tgtFile)) {
			GGrammar srcGram = extractGrammar(fromSource + srcFile);
			GGrammar tgtGram = extractGrammar(fromTarget + tgtFile);
			res += ("<right(ver,6)> <sep>" + oneLineDiffs(srcGram, tgtGram, sep));
		}
	}
    return intercalate("\n", res);
}


// A map showing what versions each production rule corresponds to:
private alias UsageData
	= map[GProd, list[str]];


// Work out (and return) which rules are used by which versions:
public UsageData getUsage(loc base, list[str] versions, str dotSuffix)
{
	UsageData usedBy = ();
	void recordUse(GProd p, str ver) { if (p notin usedBy) usedBy[p] = []; usedBy[p] += ver; }
	for (ver <- versions) {
		GGrammar pyg = extractGrammar(base+(ver+dotSuffix));
		// Just collect usage information for each rule:
		for (p <- pyg.P) { 	
			recordUse(p, ver);
		}
	}
	return usedBy;
}

// Return a list with the number of rules in each version
public list[int] countRules(loc base, list[str] versions)
{
	counts = for (ver <- versions) {
		GGrammar pyg = extractGrammar(base+(ver+dot(MENHIR_GRAMMAR_SUFFIX)));
		append(size(pyg.P));

	}
	return counts;
}


// Invert the usedBy map to give partitions, a map from version-sets to lists of rules
private map[str, list[GProd]] partitionRules(UsageData usedBy, list[str] versions)
{
	map[str, list[GProd]] modules = ();
	for (prod <- usedBy) {
		vers = for (ver <- versions) { 
			if (ver in usedBy[prod])
				append("<right(ver,6)>");
			else
				append("      ");
		}
		str verLabel = intercalate(" ", vers);
		if (verLabel notin modules) 
			modules[verLabel] = [];
		modules[verLabel] += prod;
	}
	return modules;
}

// Generate a mly file with the %token and %start declarations for a version
private void writeTokens(loc parserDir, list[str] versions, loc moduleDir)
{
	for (ver <- versions) {
		GGrammar pyg = extractGrammar(parserDir+(ver+dot(MENHIR_GRAMMAR_SUFFIX)));
		str filename = "_<ver>_tokens<dot(MENHIR_GRAMMAR_SUFFIX)>";
		loc outfile = moduleDir + filename;
		writeFile(outfile, "// Tokens for version: <ver>\n");
		appendToFile(outfile, "// Generated by CompareGrammars on <today()>\n\n");
		list[str] tokenDecls = menhirPrelude(pyg);
		appendToFile(outfile, ["<s>\n" | s <- tokenDecls]);	
		appendToFile(outfile, "\n%%\n");	
	}

}

// Split the parsers into modules, generate all relevant .mly files
public void modularise(UsageData usedBy, list[str] versions, loc moduleDir)
{
	// First partition rules based on what versions they're in:
	map[str, list[GProd]] partitions = partitionRules(usedBy, versions);
	// Now, for each parition, write a .mly file with the rules:
	for (verLabel <- partitions) {
		// Work out the filename (important for collecting version-fragments later):
		list[str] verList = [v | v <- split(" ", verLabel) && size(v)>0];
		str filename = "_<intercalate("_", verList)>_<dot(MENHIR_GRAMMAR_SUFFIX)>";
		loc outfile = moduleDir + filename;
		// Write the grammar rules:
		println("Writing <size(partitions[verLabel])> rules to file <outfile>");
		writeFile(outfile, "// Grammar for versions: <verLabel>\n");
		appendToFile(outfile, "// Generated by CompareGrammar on <today()>\n\n");
		GGrammar gmodule = tidyGrammar(partitions[verLabel]);
		list[str] mlyContents = strMenhir(gmodule, false, true);  // No tokens, everything public
		appendToFile(outfile, ["<s>\n" | s <- mlyContents]);	
	}
}

// Show the number of rules in each module:
public void countModules(UsageData usedBy, list[str] versions)
{
	map[str, list[GProd]] partitions = partitionRules(usedBy, versions);
	// Sort by module/partition size and print:
	labels = reverse(sort(["<right("<size(partitions[v])>",2)>: <v>" | v <- partitions]));
	for (str v <- labels) {
		print("<v>\n");  // One partition on each line
	}
}


// Print the NxN matrix of Jaccard distances, based on counting shared-rules
void jaccardFromRules(UsageData usedBy, list[str] versions)
{
	// Map version to total number of rules for that version:
	map[str, int] totalCount = (v:0 | v <- versions);
	// Map version-pair to counts for shared-rules:
	map[tuple[str, str], int] sharedCount = ();
	// Record that a rule has been used by two versions
	void updateCount(str ver1, str ver2) { 
		if (ver1 >= ver2) return;
		tuple[str, str] key = <ver1, ver2>;
		if (key notin sharedCount) sharedCount[key] = 0; sharedCount[key] += 1; 
	}
	// First collect the data on total no. of rules, and no. of shared rules
	for (prod <- usedBy) {
		vers = usedBy[prod];
		for (str v1 <- vers) {
			totalCount[v1] += 1; 
			for (str v2 <- vers)
				updateCount(v1, v2);
		}
	}
	// Now print the (dis)similiarity matrix:
	void printSimilarity(str ver1, str ver2) {
		if (ver1 >= ver2) return;
		int inter = sharedCount[<ver1, ver2>];
		int union = totalCount[ver1] + totalCount[ver2] - inter;
		real jaccard_diff = 1.0 - (toReal(inter) / toReal(union));    
		print("<round(jaccard_diff,.001)>, ");
	}
	for (str v1 <- versions) {
		print("  ");
		for (str v2 <- versions) 
			printSimilarity(v1, v2);
		println("# <v1>");
	}
}


///////////////////////////////////////
///// Site-specific test routines /////
///////////////////////////////////////


// Compare two Python EBNF versions, output to text file
public void compareTwo(str ver1, str ver2) 
	= compareTwo(pyg(), 
		ver1+dot(PYTHON_GRAMMAR_SUFFIX), ver2+dot(PYTHON_GRAMMAR_SUFFIX), 
		just(res("diff-<ver1>-<ver2>.txt")));


// Diff the set of Java grammars:
public void javaDiff() 
{
	loc javaFolder = cwd("java-grammars/extracted");
	// Make sure we get these in the right order:
	list[str] javaGrammars = ["java-<k>-<v><dot(BGF_GRAMMAR_SUFFIX)>" | v <- [1,2,3], k <- ["impl", "read"]];
	Maybe[loc] gdtFile = Maybe::just(res("java-metrics.txt"));
	for (s <- compareList(javaFolder, javaGrammars, gdtFile)) 
		println(s);
}


public void c() = compareOneAgainstAll(pyg("3.0.txt"), res("3-diff-all.txt"));


public void qc(bool incremental) = quickCompareFolder(pyg(), incremental);
public void qc() = qc(true);

// Diffs for a particular series: all compared with first in series
public void qcver(str ver) {
	loc base = pyg();
	list[str] files = getPythonGrammarFiles(base);
	files = [f | str f <- files, rexpMatch(f,"^[<ver>].*")];  // Match ver with start of filename
	quickCompareList(base, files, false);
} 
// So try any of: qcver("2");  qcver("3"); qcver("23");

public void cff() = findNearestFactorial(pyg(), getPythonGrammarFiles(pyg()), 6);

public void v() {
	println("Compare tarball source with grammar from documentation");
	println(diffTwoFoldersMetrics(pyg(), PYTHON_GRAMMAR_SUFFIX, pydoc(""), PYTHON_GRAMMAR_SUFFIX, AMP_SEP));
	println("Compare tarball source with (initial) bisonified parser");
	println(diffTwoFoldersMetrics(pyg(), PYTHON_GRAMMAR_SUFFIX, genp(""), BISON_GRAMMAR_SUFFIX, AMP_SEP));
	println("Compare bisonified parser with conflict-free parser");
	println(diffTwoFoldersMetrics(genp(""), BISON_GRAMMAR_SUFFIX, cfree(""), BISON_GRAMMAR_SUFFIX, AMP_SEP));
	println("Compare tarball source with conflict-free parser");
	println(diffTwoFoldersMetrics(pyg(), PYTHON_GRAMMAR_SUFFIX, cfree(""), BISON_GRAMMAR_SUFFIX, AMP_SEP));
}


// Compre every Python grammar to its predecessor; write detailed diffs to a file:
public void compareAll(loc base, Maybe[loc] gdtFile) 
{
	for (str s <- compareFolder(base, gdtFile)) 
		println(s);
}
public void compareAll() = compareAll(pyg(), just(res("pygram-diffs.txt"))); 


// Work out the Jaccard distances for the menhir parsers:
public void jm() 
{
	loc parserDir = wip("menhir")+"04-conflictfree-menhir";
	list[str] versions = s2_versions + s3_versions;
	UsageData usedBy = getUsage(parserDir, versions, dot(MENHIR_GRAMMAR_SUFFIX));
	jaccardFromRules(usedBy, versions);
}


// Work out the Jaccard distances for the major versions (using original EBNF):
public void jAll() 
{
	loc ebnfDir = pyg();
	UsageData usedBy = getUsage(ebnfDir, allMajorVersions, dot(PYTHON_GRAMMAR_SUFFIX));
	jaccardFromRules(usedBy, allMajorVersions);
	
}
// Do the modularisation: split the grammars in the 04 directory, output modules to the 07 directory
// Also write an analysis of the modules (what modules in what version)
public void m(bool writeModules) 
{
	loc parserDir = wip("menhir")+"04-conflictfree-menhir";
	loc moduleDir = wip("menhir")+"07-menhir-modules";
	list[str] versions = s2_versions;// + s3_versions;
	UsageData usedBy = getUsage(parserDir, versions, dot(MENHIR_GRAMMAR_SUFFIX));
	if (writeModules) {	
		writeTokens(parserDir, versions, moduleDir);
		modularise(parserDir, usedBy, versions, moduleDir);
	}
	countModules(usedBy, versions);
	// Last line is total no. of rules per version:
	println("Totals: & " + intercalate(" & ", countRules(parserDir, versions)));
}

// Just do the module analysis, don't write any new grammar files:
public void m() = m(false);

// Produce the data for the nominal and structural metric changes, series 1, 2 and 3
// Write as list definitions (so they can be pasted into a Python script) 
public void ralfGraph()
{
  loc ebnfDir = pyg();
  for (str series <- ["1", "2", "3"]) {
  	list[str] files = [v+dot(PYTHON_GRAMMAR_SUFFIX) | v <- allMajorVersions, startsWith(v, series)];
  	list[tuple[str,int,int]] results = quickCompareRalf(ebnfDir, files);
  	println("# Data for series <series>:");
  	println("s<series>_ver = [" + intercalate(", ",["\'<r[0]>\'" | r <- results]) + "]");
  	println("s<series>_nom = [" + intercalate(", ",["<r[1]>" | r <- results]) + "]");
  	println("s<series>_str = [" + intercalate(", ",["<r[2]>" | r <- results]) + "]");
  }
  println();
}



