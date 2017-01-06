@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pyparse::misc::SiteSpecific

// Just hard-code the names of some local folders here for convenience


loc cwd(str f) = |cwd:///| + f;

loc pyg() = cwd("python-grammars");
loc pyg(str f) = pyg() + f;
loc pydoc(str f) = pyg("from-doc") + f;
loc genp(str f) = pyg("bisonified-parsers") + f;
loc pyglu(str f) = pyg("manual-glue") + f;
loc genglu(str f) = pyg("generated-glue") + f;
loc cfree(str f) = pyg("conflictfree-parsers") + f;

loc wip() = cwd("work-in-progress");
loc wip(str f) = wip() + f;
loc res() = cwd("results");
loc res(str f) = res() + f;

