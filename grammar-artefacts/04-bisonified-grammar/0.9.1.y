// Generated (bisonified) from 0.9.1.txt on 2016-11-23 at 16:45:39 +0000

%{
	int yylex (void);
	extern int yylineno;
	extern char *yytext;
	void yyerror (char const *);
%}

// 48 tokens, in alphabetical order:
%token AND BACKQUOTE BREAK CLASS COLON COMMA DEDENT DEF DEL DOT ELIF ELSE
%token ENDMARKER EQUAL EXCEPT FINALLY FOR FROM GREATER IF IMPORT IN INDENT
%token IS LBRACE LESS LPAR LSQB MINUS NAME NEWLINE NOT NUMBER OR PASS PERCENT
%token PLUS PRINT RAISE RBRACE RETURN RPAR RSQB SLASH STAR STRING TRY WHILE

%start start


%%

start
	: file_input
	| eval_input
	| single_input
	| expr_input
	;
single_input // Used in: start
	: NEWLINE
	| simple_stmt
	| compound_stmt NEWLINE
	;
file_input // Used in: start
	: star_NEWLINE_stmt ENDMARKER
	;
pick_NEWLINE_stmt // Used in: star_NEWLINE_stmt
	: NEWLINE
	| stmt
	;
star_NEWLINE_stmt // Used in: file_input, star_NEWLINE_stmt
	: star_NEWLINE_stmt pick_NEWLINE_stmt
	| %empty
	;
expr_input // Used in: start
	: testlist NEWLINE
	;
eval_input // Used in: start
	: testlist ENDMARKER
	;
funcdef // Used in: compound_stmt
	: DEF NAME parameters COLON suite
	;
parameters // Used in: funcdef, classdef
	: LPAR fplist RPAR
	| LPAR RPAR
	;
fplist // Used in: parameters, fplist, fpdef
	: fpdef
	| fplist COMMA fpdef
	;
fpdef // Used in: fplist
	: NAME
	| LPAR fplist RPAR
	;
stmt // Used in: pick_NEWLINE_stmt, plus_stmt
	: simple_stmt
	| compound_stmt
	;
simple_stmt // Used in: single_input, stmt, suite
	: expr_stmt
	| print_stmt
	| pass_stmt
	| del_stmt
	| flow_stmt
	| import_stmt
	;
expr_stmt // Used in: simple_stmt
	: star_exprlist_EQUAL exprlist NEWLINE
	;
star_exprlist_EQUAL // Used in: expr_stmt, star_exprlist_EQUAL
	: star_exprlist_EQUAL exprlist EQUAL
	| %empty
	;
print_stmt // Used in: simple_stmt
	: PRINT star_test_COMMA test NEWLINE
	| PRINT star_test_COMMA NEWLINE
	;
star_test_COMMA // Used in: print_stmt, star_test_COMMA
	: star_test_COMMA test COMMA
	| %empty
	;
del_stmt // Used in: simple_stmt
	: DEL exprlist NEWLINE
	;
pass_stmt // Used in: simple_stmt
	: PASS NEWLINE
	;
flow_stmt // Used in: simple_stmt
	: break_stmt
	| return_stmt
	| raise_stmt
	;
break_stmt // Used in: flow_stmt
	: BREAK NEWLINE
	;
return_stmt // Used in: flow_stmt
	: RETURN testlist NEWLINE
	| RETURN NEWLINE
	;
raise_stmt // Used in: flow_stmt
	: RAISE expr COMMA expr NEWLINE
	| RAISE expr NEWLINE
	;
import_stmt // Used in: simple_stmt
	: IMPORT NAME star_COMMA_NAME NEWLINE
	| FROM NAME IMPORT pick_STAR_NAME NEWLINE
	;
star_COMMA_NAME // Used in: import_stmt, star_COMMA_NAME, pick_STAR_NAME
	: star_COMMA_NAME COMMA NAME
	| %empty
	;
pick_STAR_NAME // Used in: import_stmt
	: STAR
	| NAME star_COMMA_NAME
	;
compound_stmt // Used in: single_input, stmt
	: if_stmt
	| while_stmt
	| for_stmt
	| try_stmt
	| funcdef
	| classdef
	;
if_stmt // Used in: compound_stmt
	: IF test COLON suite star_ELIF ELSE COLON suite
	| IF test COLON suite star_ELIF
	;
star_ELIF // Used in: if_stmt, star_ELIF
	: star_ELIF ELIF test COLON suite
	| %empty
	;
while_stmt // Used in: compound_stmt
	: WHILE test COLON suite ELSE COLON suite
	| WHILE test COLON suite
	;
for_stmt // Used in: compound_stmt
	: FOR exprlist IN exprlist COLON suite ELSE COLON suite
	| FOR exprlist IN exprlist COLON suite
	;
try_stmt // Used in: compound_stmt
	: TRY COLON suite star_001 FINALLY COLON suite
	| TRY COLON suite star_001
	;
star_001 // Used in: try_stmt, star_001
	: star_001 except_clause COLON suite
	| %empty
	;
except_clause // Used in: star_001
	: EXCEPT expr opt_COMMA_expr
	| EXCEPT
	;
opt_COMMA_expr // Used in: except_clause
	: COMMA expr
	| %empty
	;
suite // Used in: funcdef, if_stmt, star_ELIF, while_stmt, for_stmt, try_stmt, star_001, classdef
	: simple_stmt
	| NEWLINE INDENT star_NEWLINE plus_stmt DEDENT
	;
star_NEWLINE // Used in: suite, star_NEWLINE, plus_stmt
	: star_NEWLINE NEWLINE
	| %empty
	;
plus_stmt // Used in: suite, plus_stmt
	: plus_stmt stmt star_NEWLINE
	| stmt star_NEWLINE
	;
test // Used in: print_stmt, star_test_COMMA, if_stmt, star_ELIF, while_stmt, test, testlist, star_COMMA_test
	: and_test
	| test OR and_test
	;
and_test // Used in: test, and_test
	: not_test
	| and_test AND not_test
	;
not_test // Used in: and_test, not_test
	: NOT not_test
	| comparison
	;
comparison // Used in: not_test, comparison
	: expr
	| comparison comp_op expr
	;
comp_op // Used in: comparison
	: LESS
	| GREATER
	| EQUAL
	| GREATER EQUAL
	| LESS EQUAL
	| LESS GREATER
	| IN
	| NOT IN
	| IS
	| IS NOT
	;
expr // Used in: raise_stmt, except_clause, opt_COMMA_expr, comparison, expr, subscript, opt_expr, exprlist, star_COMMA_expr
	: term
	| expr pick_PLUS_MINUS term
	;
pick_PLUS_MINUS // Used in: expr, factor
	: PLUS
	| MINUS
	;
term // Used in: expr, term
	: factor
	| term pick_old_multop factor
	;
pick_old_multop // Used in: term
	: STAR
	| SLASH
	| PERCENT
	;
factor // Used in: term, factor
	: pick_PLUS_MINUS factor
	| atom star_trailer
	;
star_trailer // Used in: factor, star_trailer
	: star_trailer trailer
	| %empty
	;
atom // Used in: factor, baselist, star_002
	: LPAR opt_testlist RPAR
	| LSQB opt_testlist RSQB
	| LBRACE RBRACE
	| BACKQUOTE testlist BACKQUOTE
	| NAME
	| NUMBER
	| STRING
	;
opt_testlist // Used in: atom, trailer
	: testlist
	| %empty
	;
trailer // Used in: star_trailer
	: LPAR opt_testlist RPAR
	| LSQB subscript RSQB
	| DOT NAME
	;
subscript // Used in: trailer
	: expr
	| opt_expr COLON opt_expr
	;
opt_expr // Used in: subscript
	: expr
	| %empty
	;
exprlist // Used in: expr_stmt, star_exprlist_EQUAL, del_stmt, for_stmt
	: expr star_COMMA_expr COMMA
	| expr star_COMMA_expr
	;
star_COMMA_expr // Used in: exprlist, star_COMMA_expr
	: star_COMMA_expr COMMA expr
	| %empty
	;
testlist // Used in: expr_input, eval_input, return_stmt, atom, opt_testlist, arguments
	: test star_COMMA_test COMMA
	| test star_COMMA_test
	;
star_COMMA_test // Used in: testlist, star_COMMA_test
	: star_COMMA_test COMMA test
	| %empty
	;
classdef // Used in: compound_stmt
	: CLASS NAME parameters EQUAL baselist COLON suite
	| CLASS NAME parameters COLON suite
	;
baselist // Used in: classdef
	: atom arguments star_002
	;
star_002 // Used in: baselist, star_002
	: star_002 COMMA atom arguments
	| %empty
	;
arguments // Used in: baselist, star_002
	: LPAR testlist RPAR
	| LPAR RPAR
	;

%%

#include <stdio.h>
void yyerror (char const *s)
{
	fprintf (stderr, "%d: %s with [%s]\n", yylineno, s, yytext);
}

