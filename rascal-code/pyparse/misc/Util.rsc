@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pyparse::misc::Util

import Prelude;


// Misc. stuff (mostly file-handling) that didn't really belong in any one place...


public str BISON_GAMMAR_SUFFIX = "y";
public str MENHIR_GAMMAR_SUFFIX = "mly";
public str BGF_GAMMAR_SUFFIX = "bgf";
public str PYTHON_GRAMMAR_SUFFIX = "txt";
public str EBNF_GAMMAR_SUFFIX = "ebnf";
public str GLUE_FILE_SUFFIX = "glue";

public str BISON_GAMMAR_DOT_SUFFIX = "." + BISON_GAMMAR_SUFFIX;
public str MENHIR_GAMMAR_DOT_SUFFIX = "." + MENHIR_GAMMAR_SUFFIX;
public str BGF_GAMMAR_DOT_SUFFIX = "." + BGF_GAMMAR_SUFFIX;
public str PYTHON_GRAMMAR_DOT_SUFFIX = "." + PYTHON_GRAMMAR_SUFFIX;
public str GLUE_FILE_DOT_SUFFIX = "." + GLUE_FILE_SUFFIX;

public str CSV_SEP = ":";
public str AMP_SEP = "&";
public str TEX_ENDL = "\\\\";

// To compare a grammar with the previous one we need to sort filenames by version number...
// Can't use alphabetical sort because of minor version numbers (e.g. we get ["2.7.12", "2.7.1", "2.7.2", "2.7"])

// Pad the minor version number with spaces so the filenames will sort correctly
public str padVersionName(str filename) 
{
	nums = split(".", filename);
	str minor = (size(nums) < 3) ? "" : nums[2];
	return "<nums[0]>.<nums[1]>.<right(minor, 2, " ")>";
}
public str padVersionName(str filename, str suffix) 
{
	filename = replaceLast(filename, suffix, "");
	return padVersionName(filename);
}

// Return a list of the Python grammar files in version-number order:
public list[str] sortPyGramByVersion(loc folder, str suffix)
{
	list[str] files = [f | f <- listEntries(folder), isFile(folder+f) && /^[0-9.]+<suffix>$/ := f]; 
	return sort(files, bool (str a, str b) { return padVersionName(a, suffix) < padVersionName(b, suffix);});
}
// Default uses suffix for Python EBNF files:
public list[str] sortPyGramByVersion(loc folder) = sortPyGramByVersion(folder, PYTHON_GRAMMAR_SUFFIX);

public list[str] getPythonGrammarFiles(loc folder)
{
	assert isDirectory(folder) : "<folder> must be a folder";
	// First try to pick out any Python grammar files:
	list[str] files = sortPyGramByVersion(folder, PYTHON_GRAMMAR_SUFFIX);
	if (isEmpty(files))	// Then take any .y files:
		files = sortPyGramByVersion(folder, BISON_GAMMAR_SUFFIX);
	if (isEmpty(files))	// Then take any BGF files:
		files = sortPyGramByVersion(folder, BGF_GAMMAR_SUFFIX);
	return files;
}

public list[str] getAnyGrammarFiles(loc folder)
{
	assert isDirectory(folder) : "<folder> must be a folder";
	bool isGram(str file) = endsWith(file,BGF_GAMMAR_DOT_SUFFIX) || endsWith(file,BISON_GAMMAR_DOT_SUFFIX);
	list[str] files = [f | f <- listEntries(folder), isFile(folder+f) && isGram(f)];
	return files;
}
// Delete the extension (including the dot) in a filename:
public str delExt(loc base, str file) = replaceLast((base+file).file, "."+(base+file).extension, "");

str rpadFilename(loc base, str filename, int padding) = left(delExt(base,filename), padding, " ");
str rpadFilename(loc base, str filename) = rpadFilename(base, filename, 6);  // Suits Python files

// date/time is all messed up; this is what I want:
//str today() = printDateTime(now(), "YYYY-MM-dd \'at\' HH:mm:ss ZZ");
str today() = replaceAll(replaceAll("<now()>", "$", ""), "T", " at ");
