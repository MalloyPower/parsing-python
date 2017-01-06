@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pyparse::ApplyManualGlue

/*
 * This is the code I use to apply the manual glue to the bisonified parser.
 * It's really just some bits and pieces to pull the other code (diffs, transforms) together.
 */
 
import Prelude;

import util::Maybe;


import pyparse::MyGrammar;
import pyparse::misc::SiteSpecific;
import pyparse::misc::Util;

import pyparse::extract::Extracters;
import pyparse::CompareGrammars;
import pyparse::RunTransformation;

import pyparse::RuleDuplicates;

// How many errors in the XBFG are you prepared to ignore:
int TOLERANCE = 20;
int NO_TOLERANCE = 0;

void compare(GGrammar g1, GGrammar g2, loc filename)
{
	writeFile(filename, "Parser comparison generated on: <today()>\n");
	appendToFile(filename, gdtv_str(g1, g2));
}

// Usual comparison, but also check for non-t renamings
void compareTwoParsers(loc yFile1, loc yFile2, loc diffFile)
{
	println("Parsing <yFile1>");
	GGrammar p1 = extractGrammar(yFile1);
	println("Parsing <yFile2>");
	GGrammar p2 = extractGrammar(yFile2);
	writeFile(diffFile, "// Diff <yFile1.file> vs. <yFile2.file>; generated on <today()>\n");
	<p2, toReplace> = iteratedEquate(p1, p2);
	if (size(toReplace) > 0)
		appendToFile(diffFile, "<size(toReplace)> non-t renamings can be done:\n");
	for (<oldNT, newNT> <- toReplace)
		appendToFile(diffFile, "rename <oldNT> to <newNT> globally.\n");
	appendToFile(diffFile, gdtv_str(p1, p2));
}



// Apply the transformations to g1, compare the result with g2 modulo non-t renaming.
tuple[GGrammar, GGrammar] transformEquate(loc gramfile1, list[loc] manualGlue, loc gramfile2, loc outfile)
{
	GGrammar g1 = runTransforms(gramfile1, manualGlue, outfile, NO_TOLERANCE);  
	GGrammar g2 = extractGrammar(gramfile2);
	<g2, toReplace> = iteratedEquate(g1, g2);
	for (<oldNT, newNT> <- toReplace)
		println("rename <oldNT> to <newNT>.");
	return <g1,g2>;

}


///////////////////////////////////////
///// Site-specific test routines /////
///////////////////////////////////////

// Temporary (work-in-progress) locations for parsers and glue
loc ploc(str f) = cwd("work-in-progress") + f;
loc pgloc(str f) = ploc("manual-glue") + f;

// Return the neames of the glue files for manual transformations.
list[loc] getGlueFrom(loc folder, str ver)
{
	list[str] txfrmList = ["rename", "remove", "commas", "arglist", "smallstmt"];
	//txfrmList = ["rename", "remove", "commas"];
	list[loc] manualGlue = [folder + "<ver>-<t><GLUE_FILE_DOT_SUFFIX>" | str t <- txfrmList] ;
	return manualGlue;
}

// Read the 2.7.2 grammar, perform manual transformations, and diff it with Brian's parser:
// This was where the original manual glue files were constructed...
void b(str ver)
{
	list[loc] manualGlue = getGlueFrom(ploc(""), ver);
	str infile = "<ver><BISON_GAMMAR_DOT_SUFFIX>";
	str outfile = "<ver>.transformed<BISON_GAMMAR_DOT_SUFFIX>";
	<g1,g2> = transformEquate(ploc(infile), manualGlue, ploc("parse.y"), ploc(outfile));
	compare(g1, g2, ploc("curr-parser.diffs.txt"));
}
void b() = b("2.7.2");

// Apply the manual glue to a bisonified parser to get a (hopefully) conflict-free one.
// We identify the glue files (currently six of them) using the version name.
void makeParseable(str ver)
{
	list[loc] manualGlue = getGlueFrom(pyglu(""), ver);
	loc infile = genp("<ver><BISON_GAMMAR_DOT_SUFFIX>");    // bisonified version
	loc outfile = cfree("<ver><BISON_GAMMAR_DOT_SUFFIX>");  // conflict-free version
	runTransforms(infile, manualGlue, outfile, TOLERANCE);
}
// Like the previous version, but uses the work-in-progress folders:
void makeParseable_temp(str ver)
{
	list[loc] manualGlue = getGlueFrom(pgloc(""), ver);
	loc infile = genp("<ver><BISON_GAMMAR_DOT_SUFFIX>");    // bisonified version
	loc outfile = ploc("<ver><BISON_GAMMAR_DOT_SUFFIX>");  // conflict-free version
	runTransforms(infile, manualGlue, outfile, TOLERANCE);
}
void mp(str ver) = makeParseable_temp(ver);

// Get all the 2.x bisonified grammars and apply the manual glue to them.
void makeAll(str majorVer)
{
	list[str] fs = getPythonGrammarFiles(pyg()); // Just used to get grammar names
	for (str v <- fs, startsWith(v, majorVer))
		makeParseable(replaceLast(v, PYTHON_GRAMMAR_DOT_SUFFIX, ""));
}
void ma() = makeAll("3.");

void c()
{
	<g1,g2> = transformEquate(ploc("test-in.y"), [ploc("test-manual.glue")], ploc("test-out.y"), ploc("test-edited.y"));
	//compare(g1, g2, ploc("test-diffs.txt"));
}
