@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pygrat::ApplyManualGlue

/*
 * This is the code I use to apply the manual glue to the bisonified parser.
 * It's really just some bits and pieces to pull the other code (diffs, transforms) together.
 */
 
import Prelude;

import util::Maybe;


import pygrat::MyGrammar;
import pygrat::misc::SiteSpecific;
import pygrat::misc::Util;

import pygrat::extract::Extracters;
import pygrat::CompareGrammars;
import pygrat::RunTransformation;

import pygrat::RuleDuplicates;

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



// Apply the manual glue to a bisonified parser to get a (hopefully) conflict-free one.
// We identify the glue files (currently six of them) using the version name.
void makeParseable(str ver)
{
	list[loc] manualGlue = getGlueFrom(pyglu(""), ver);
	loc infile = genp("<ver><dot(BISON_GRAMMAR_SUFFIX)>");    // bisonified version
	loc outfile = cfree("<ver><dot(BISON_GRAMMAR_SUFFIX)>");  // conflict-free version
	runTransforms(infile, manualGlue, outfile, TOLERANCE);
}


// Apply the manual glue to the python.org EBNF to get menhir parsers
void ebnf2menhir()
{
	loc working =  wip("menhir");
	loc infolder = working + "01-ebnf-major-versions";
	loc glufolder = working + "03-handwritten-xbgf";
	loc outfolder = working + "04-conflictfree-menhir";
	for (str infile <- sortPyGramByVersion(infolder, PYTHON_GRAMMAR_SUFFIX))
	{
		str filestem = replaceLast(infile, dot(PYTHON_GRAMMAR_SUFFIX), "");
		str glufile = filestem + "-manual" + dot(GLUE_FILE_SUFFIX);
		str outfile = filestem + dot(MENHIR_GRAMMAR_SUFFIX);
		println("Translating <infile> using <glufile> to <outfolder>");
		runTransforms(infolder+infile, glufolder+glufile, outfolder+outfile);
	}
}

// Apply the generated glue to menhir parsers to get bison parsers
void menhir2bison()
{
	loc working =  wip("menhir");
	loc infolder = working + "04-conflictfree-menhir";
	loc glufolder = working + "05-generated-xbgf";
	loc outfolder = working + "06-conflictfree-bison";
	for (str infile <- sortPyGramByVersion(infolder, MENHIR_GRAMMAR_SUFFIX))
	{
		str filestem = replaceLast(infile, dot(MENHIR_GRAMMAR_SUFFIX), "");
		str glufile = filestem + "-bisonify" + dot(GLUE_FILE_SUFFIX);
		str outfile = filestem + dot(BISON_GRAMMAR_SUFFIX);
		println("Translating <infile> using <glufile> to <outfolder>");
		runTransforms(infolder+infile, glufolder+glufile, outfolder+outfile);
	}
}




