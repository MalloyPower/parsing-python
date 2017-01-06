@contributor{James Power - jpower@cs.nuim.ie - Maynooth, Ireland}
module pyparse::extract::PyTokens

import pyparse::MyGrammar;

/* 
 * For reading the Python grammars: map characters to token names.
 */
 
public map[str,str] pyToken = 
(  

  "@"     : "AT",
  "&="    : "AMPEREQUAL",
  "&"     : "AMPERSAND",
  "-\>"   : "ARROW",
  "@="    : "ATEQ",
  "`"     : "BACKQUOTE",
  "|"     : "BAR",
  "^"     : "CIRCUMFLEX",
  "^="    : "CIRCUMFLEXEQUAL",
  ":"     : "COLON",
  ","     : "COMMA",
  "."     : "DOT",
  "//"    : "DOUBLESLASH",
  "//="   : "DOUBLESLASHEQUAL",
  "**"    : "DOUBLESTAR",
  "**="   : "DOUBLESTAREQUAL",
  "=="    : "EQEQUAL",
  "="     : "EQUAL",
  "\>"    : "GREATER",
  "\>="   : "GREATEREQUAL",
  "\<\>"  : "GRLT",
  "{"     : "LBRACE",
  "\<\<"  : "LEFTSHIFT",
  "\<\<=" : "LEFTSHIFTEQUAL",
  "\<"    : "LESS",
  "\<="   : "LESSEQUAL",
  "("     : "LPAR",
  "["     : "LSQB",
  "-="    : "MINEQUAL",
  "-"     : "MINUS",
  "!="    : "NOTEQUAL",
  "%"     : "PERCENT",
  "%="    : "PERCENTEQUAL",
  "+"     : "PLUS",
  "+="    : "PLUSEQUAL",
  "}"     : "RBRACE",
  "\>\>"  : "RIGHTSHIFT",
  "\>\>=" : "RIGHTSHIFTEQUAL",
  ")"     : "RPAR",
  "]"     : "RSQB",
  ";"     : "SEMI",
  "/"     : "SLASH", 
  "/="    : "SLASHEQUAL",
  "*"     : "STAR",
  "*="    : "STAREQUAL",
  "..."   : "THREE_DOTS",
  "~"     : "TILDE",
  "|="    : "VBAREQUAL",
    
  "and"      : "AND",
  "as"       : "AS",
  "async"    : "ASYNC",
  "assert"   : "ASSERT",
  "await"    : "AWAIT",
  "break"    : "BREAK",
  "class"    : "CLASS",
  "continue" : "CONTINUE",
  "def"      : "DEF",
  "del"      : "DEL",
  "elif"     : "ELIF",
  "else"     : "ELSE",
  "except"   : "EXCEPT",
  "exec"     : "EXEC",
  "finally"  : "FINALLY",
  "for"      : "FOR",
  "from"     : "FROM",
  "global"   : "GLOBAL",
  "if"       : "IF",
  "import"   : "IMPORT",
  "in"       : "IN",
  "is"       : "IS",
  "lambda"   : "LAMBDA",
  "nonlocal" : "NONLOCAL",
  "not"      : "NOT",
  "or"       : "OR",
  "pass"     : "PASS",
  "print"    : "PRINT",
  "raise"    : "RAISE",
  "return"   : "RETURN",
  "try"      : "TRY",
  "while"    : "WHILE",
  "with"     : "WITH",
  "yield"    : "YIELD",

  "None"     : "NONE",
  "True"     : "TRUE",
  "False"    : "FALSE"
  
 );
 
 
 // Apply the above mappings to a grammar (only changes RHSs):
 public GGrammar fixTokens(GGrammar g)
 {
 	newProds = for (GProd p <- g.P) {
 		newRHS = visit(p.rhs) {
 			case terminal(t) => terminal(t in pyToken ? pyToken[t] : t)
 		}
 		append production(p.lhs, newRHS);
 	}
 	return grammar(g.N, newProds, g.S);
 }
 
 
 
 