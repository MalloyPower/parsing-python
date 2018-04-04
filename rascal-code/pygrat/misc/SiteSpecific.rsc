@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pygrat::misc::SiteSpecific

// Just hard-code the names of some local folders here for convenience


loc cwd(str f) = |cwd:///| + f;

loc pyg() = cwd("..") + "grammar-artefacts";
loc pyg(str f) = pyg() + f;
loc pydoc(str f) = pyg("from-doc") + f;
loc pyglu(str f) = pyg("03-handwritten-xbgf") + f;
loc genp(str f) = pyg("04-conflictfree-menhir") + f;
loc genglu(str f) = pyg("05-generated-xbgf") + f;
loc cfree(str f) = pyg("06-conflictfree-bison") + f;

loc wip() = cwd("work-in-progress");
loc wip(str f) = wip() + f;
loc res() = cwd("results");
loc res(str f) = res() + f;

public list[str] s2_versions = ["2.0", "2.2", "2.4", "2.5", "2.6", "2.7"];
public list[str] s3_versions = ["3.0", "3.1", "3.2", "3.3.0", "3.5.0", "3.6.0"];

// All the major versions, from all three series:
public list[str] allMajorVersions = 
	["1.0.1", "1.1", "1.2", "1.3", "1.4", "1.5", "1.6"] +
	["2.0", "2.1", "2.2", "2.3", "2.4", "2.5", "2.6", "2.7"] +
	["3.0", "3.1", "3.2", "3.3.0", "3.4.0", "3.5.0", "3.6.0"];

