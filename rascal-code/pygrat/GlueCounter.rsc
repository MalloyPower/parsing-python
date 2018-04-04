@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pygrat::GlueCounter

/*
 * Some simple routines to count Glue (XBGF) commands and to compare Glue files.
 */

import Prelude;
import util::Maybe;
import util::Math;

import grammarlab::io::GLUE;   // loadGlue
import grammarlab::language::glue::abstract::Top;  // For GLUE (abstract syntax)
import grammarlab::language::X;  // XCommand

import pygrat::MyGrammar;
import pygrat::misc::SiteSpecific;
import pygrat::misc::Util;


// Read all the XBGF commands from a glue file (ignore any other commands)
list[XCommand] readGlue(loc gluefile)
{
	list[XCommand] res = [];
	for (cmd <- loadGlue(gluefile)) {
		switch(cmd) {
			case xbgf(xcmd) : res += xcmd; 
			default: println("ignoring command <cmd>");
		}
	}
    return res;
}

// Read all the glue files for a given version, merge into a single list:
list[XCommand] readGlue(list[loc] folderList, str ver)
{
	list[XCommand] res = [];
	for (folder <- folderList) {
	  list[str] files = [f | f <- listEntries(folder), isFile(folder+f) && startsWith(f,ver+"-") && endsWith(f,GLUE_FILE_SUFFIX)]; 
	  for (gluefile <- files) {
    	res += readGlue(folder+gluefile);
      }
    }
    return res;
}

// Where to get the glue files
loc manGlueFile(str ver) = pyglu("<ver>-manual<dot(GLUE_FILE_SUFFIX)>"); 
loc genGlueFile(str ver) = genglu("<ver>-bisonify<dot(GLUE_FILE_SUFFIX)>");

// Read all the (generated and manual) glue commands for a particular version of Python.
// N.B. This is site-specific, since we need to know where the glue files are.
list[XCommand] readGlueForVersion(str ver, bool includeGeneratedGlue)
{
	list[XCommand] cmds = [ ]; 
	if (includeGeneratedGlue)
		cmds += readGlue(genGlueFile(ver));
	cmds += readGlue(manGlueFile(ver));
	return cmds;
}
list[XCommand] readGlueForVersion(str ver) = readGlueForVersion(ver, true);



// Count the different kinds of command in a list of commands.
// The trick here is to use Rascal's Node::getName(node T) to get the command-kind.
map[str,int] countKinds(list[XCommand] cmds)
{
	map[str,int] counts =  ( );
	for (xcmd <- cmds) {
		str cmdName = getName(xcmd);  
		if (cmdName notin counts)
			counts[cmdName] = 0;
		counts[cmdName] += 1;
	}
	return counts;
}

// Compare two sets of commands, return number of commands added, deleted, unchanged
tuple[int,int,int] compareCommands(set[&T] cmds1, set[&T] cmds2)
{
	set[&T] added = cmds1 - cmds2;
	set[&T] deleted = cmds2 - cmds1;
	set[&T] unchanged = cmds2 & cmds1;
	return <size(added), size(deleted), size(unchanged)>;
}
tuple[int,int,int] compareCommands(list[&T] cmds1, list[&T] cmds2)
	= compareCommands(toSet(cmds1), toSet(cmds2));
	
// Want to compare a glue file for a version with those for all other versions
private real jaccard(set[&T] s1, set[&T] s2) = 1.0 - (toReal(size(s1 & s2)) / toReal(size(s1 + s2)));
private real jaccard(list[&T] s1, list[&T] s2) = jaccard(toSet(s1), toSet(s2));


void compareCommands(str ver1, str ver2)
{
	list[XCommand] cmds1 = readGlueForVersion(ver1);
	list[XCommand] cmds2 = readGlueForVersion(ver2);
	<a,d,u> = compareCommands(cmds1, cmds2);
	real j = jaccard(cmds1, cmds2);
	println("<ver1> vs. <ver2>: <a> added, <d> deleted, <u> unchanged.");
	println("\t<ver1>: size as list = <size(cmds1)>, as set = <size(toSet(cmds1))>");
	println("\t<ver2>: size as list = <size(cmds2)>, as set = <size(toSet(cmds2))>");
	println("<ver1> vs. <ver2>: total (as set) = <size(toSet(cmds1)+toSet(cmds2))>; jaccard sim=<round(100*(1-j),.01)>");
}

void compareCommands_verbose(str ver1, str ver2)
{
	list[XCommand] cmds1 = readGlueForVersion(ver1);
	list[XCommand] cmds2 = readGlueForVersion(ver2);
	list[XCommand] added = cmds1 - cmds2;
	list[XCommand] deleted = cmds2 - cmds1;
	list[XCommand] unchanged = cmds2 & cmds1;
	println("Added:\n <intercalate("\n+\t", added)>");
	println("Deleted:\n <intercalate("\n-\t", deleted)>");
	println("Unchanged:\n <intercalate("\n=\t", unchanged)>");
}

// Compare the glue files for a version to those for its immediate successor version
void compareIncremental(loc gramFolder, str gramSuffix) {
	// Get the version names:
	list[str] parsers = sortPyGramByVersion(gramFolder, gramSuffix);
	list[str] versions = [delExt(gramFolder,p) | p <- parsers];
	for (int i <- upTill(size(versions)-1)) {
		str ver1 = versions[i];
		str ver2 = versions[i+1];
		list[XCommand] cmds1 = readGlueForVersion(ver1); 
		list[XCommand] cmds2 = readGlueForVersion(ver2); 
		<a,d,u> = compareCommands(cmds1, cmds2);
		println("<versions[i]> & <versions[i+1]> & <a> & <d> & <u>\\\\");
	}
}


private list[list[real]] calcSimMatrix(list[str] versions, bool includeGeneratedGlue) 
{
	// Read in the list of XBGF commands for each version (keep versions in order):
	list[list[XCommand]] cmds = [readGlueForVersion(v,includeGeneratedGlue) | v <- versions];
	// Set up the similiarity matrix witha  zero in all entries:
	list[list[real]] simMatrix = [[0.0 | j <- versions] | i <- versions];
	// Compare each version with all its successors:
	for (int i <- upTill(size(versions))) {
		str ver1 = versions[i];
		for (int j <- [i .. size(versions)]) {  // We include j=i case just as a sanity check
			real sim = jaccard(cmds[i], cmds[j]);  
			simMatrix[i][j] = sim;
			simMatrix[j][i] = sim;
		}
	}
	return simMatrix;
}

// Calcualte and print the similarity matrix (symmetric matrix)
public void printSimMatrix(loc gramFolder, str gramSuffix, bool includeGeneratedGlue)
{
	// Get the version names:
	list[str] parsers = sortPyGramByVersion(gramFolder, gramSuffix);
	list[str] versions = [delExt(gramFolder,p) | p <- parsers];
    list[list[real]] simMatrix = calcSimMatrix(versions,includeGeneratedGlue);
	for (int i <- upTill(size(versions))) {
		println("<right(versions[i],5)> " + intercalate(" ",  ["<round(j,0.01)>" | j <- simMatrix[i]]));
	}
}

// Calcualte and print the upper-right traingle of the similarity matrix as a Python list 
public void printSimTriangle(loc gramFolder, str gramSuffix, bool includeGeneratedGlue)
{
	str INDENT = "  ";
	// Get the version names:
	list[str] parsers = sortPyGramByVersion(gramFolder, gramSuffix);
	list[str] versions = [delExt(gramFolder,p) | p <- parsers];
    list[list[real]] simMatrix = calcSimMatrix(versions,includeGeneratedGlue);
    println("dist_mat = array([");
	for (int i <- upTill(size(versions)-1)) {
		print(INDENT);
		for (int j <- [i+1 .. size(versions)]) {
		    print("<round(simMatrix[i][j],0.001)>, ");
		}  
		println(" # v<versions[i]>");
	}
	println(INDENT + "])");
}


// The glue file information we will collect for each version:
private alias KindCounts = tuple[int total, map[str,int] counts];

// List the count of each kind of XBGF command, one line per version.
public void printGlueCounts(list[loc] glueFolders, list[str] versions) 
{
  set[str] cmdTypes = { };  // All the command kinds (used by any version)
  // Count the command kinds for each version:
  map[str, KindCounts] results = ();  
  for (ver <- versions) {
	list[XCommand] cmds = readGlue(glueFolders, ver);
    map[str,int] thisVer = countKinds(cmds);
    cmdTypes += domain(thisVer);
    results[ver] = <size(cmds), thisVer>;
  }
  // Header line:
  list[str] headLine = ["Operation"] + ["<ver>" | str ver <- versions];
  println(intercalate(" <AMP_SEP> ",headLine) + " <TEX_ENDL>");     
  // Now print the kind counts for each version in turn:
  list[str] cmdTypeList = sort(cmdTypes);
  for (str cmd <- cmdTypeList) {
  	  list[str] resLine = ["<right(cmd,12)>"]
  	          + [right("<results[ver].counts[cmd] ? 0>",2) | str ver <- versions] ;
    println(intercalate(" <AMP_SEP> ",resLine) + " <TEX_ENDL>");     
  }
  // Totals line:
  list[str] totLine = ["Totals:"] + ["<results[ver].total>" | str ver <- versions];
  println(intercalate(" <AMP_SEP> ",totLine) + " <TEX_ENDL>");     
}
//  list[str] resLine = ["Ver"] + cmdTypeList + ["Total"];
//  println(intercalate(" <AMP_SEP> ",resLine) + " <TEX_ENDL>");
//  for (r <- results) {
//  	resLine = ["<right(r.version,5)>"] 
//  	        + [right("<r.counts[cmd] ? 0>",2) | str cmd <- cmdTypeList] 
//  	        + ["<r.total>"];
//    println(intercalate(" <AMP_SEP> ",resLine) + " <TEX_ENDL>");






// List the count of each kind of XBGF command, one line per version.
public void listGlueCounts(loc gramFolder, str gramSuffix, bool includeGeneratedGlue) 
{
  list[str] parsers = sortPyGramByVersion(gramFolder, gramSuffix);
  list[str] versions = [delExt(gramFolder,p) | p <- parsers];
  printGlueCounts(versions);
}

///////////////////////////////////////
///// Site-specific test routines /////
///////////////////////////////////////

// Print the command-kind counts for a single version (manual and generated glue)
void g(str ver) {
	list[XCommand] cmds = readGlueForVersion(ver);
	println("<size(cmds)> xbgf commands in total.");
	println(countKinds(cmds));
}

// Print the total and per-file average glue counts for a folder:
void cg(loc glueFolder) 
{
	suffix = GLUE_FILE_SUFFIX;
	list[str] files = [f | f <- listEntries(glueFolder), isFile(glueFolder+f) && endsWith(f,suffix)];
	files = sort(files, bool (str a, str b) { return padVersionName(a, suffix) < padVersionName(b, suffix);});
	int count = size(files);
	println("<glueFolder>: <count> <dot(suffix)>files in total");
	int total = 0; 
  	for (str glueFile <- files) {
		list[XCommand] cmds = readGlue(glueFolder+glueFile);
		total += size(cmds);
  		println("\t<glueFile> <size(cmds)>");
	}
	println("<glueFolder> total = <total>, average = <total/count>");
}

// Compare the bison-first approach with the menhir-first approach:
void printGlueCounts()
{
  cg(wip("scp-2017-grammar-artefacts") + "03-generated-xbgf");
  cg(wip("scp-2017-grammar-artefacts") + "05-handwritten-xbgf");
  cg(wip("menhir") + "03-handwritten-xbgf");
  cg(wip("menhir") + "05-generated-xbgf");
}

void printGlueTable()
{
  list[str] versions = s2_versions + s3_versions;
  loc generatedGlue = wip("scp-2017-grammar-artefacts") + "03-generated-xbgf";
  loc manualGlue = wip("scp-2017-grammar-artefacts") + "05-handwritten-xbgf";
  println("--- Bison-first version (yaccify, then elim conflicts)");
  printGlueCounts([generatedGlue, manualGlue], versions);
  //loc menhirGlue = wip("menhir") + "03-handwritten-xbgf";
  //println("--- Menhir version (elim conflicts)");
  //printGlueCounts([menhirGlue], versions);
}


