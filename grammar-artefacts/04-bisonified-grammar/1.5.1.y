// Generated (bisonified) from 1.5.1.txt on 2016-11-23 at 16:45:41 +0000

%{
	int yylex (void);
	extern int yylineno;
	extern char *yytext;
	void yyerror (char const *);
%}

// 66 tokens, in alphabetical order:
%token AMPERSAND AND ASSERT BACKQUOTE BAR BREAK CIRCUMFLEX CLASS COLON COMMA
%token CONTINUE DEDENT DEF DEL DOT DOUBLESTAR ELIF ELSE ENDMARKER EQEQUAL
%token EQUAL EXCEPT EXEC FINALLY FOR FROM GLOBAL GREATER GREATEREQUAL GRLT
%token IF IMPORT IN INDENT IS LAMBDA LBRACE LEFTSHIFT LESS LESSEQUAL LPAR
%token LSQB MINUS NAME NEWLINE NOT NOTEQUAL NUMBER OR PASS PERCENT PLUS
%token PRINT RAISE RBRACE RETURN RIGHTSHIFT RPAR RSQB SEMI SLASH STAR STRING
%token TILDE TRY WHILE

%start start


%%

start
	: file_input
	| eval_input
	| single_input
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
eval_input // Used in: start
	: testlist star_NEWLINE ENDMARKER
	;
star_NEWLINE // Used in: eval_input, star_NEWLINE
	: star_NEWLINE NEWLINE
	| %empty
	;
funcdef // Used in: compound_stmt
	: DEF NAME parameters COLON suite
	;
parameters // Used in: funcdef
	: LPAR varargslist RPAR
	| LPAR RPAR
	;
varargslist // Used in: parameters, lambdef
	: star_fpdef_COMMA pick_002
	| fpdef opt_EQUAL_test star_COMMA_fpdef opt_COMMA
	;
opt_EQUAL_test // Used in: varargslist, star_fpdef_COMMA, star_COMMA_fpdef
	: EQUAL test
	| %empty
	;
star_fpdef_COMMA // Used in: varargslist, star_fpdef_COMMA
	: star_fpdef_COMMA fpdef opt_EQUAL_test COMMA
	| %empty
	;
pick_001 // Used in: opt_COMMA_NAME, pick_002
	: DOUBLESTAR
	| STAR STAR
	;
opt_COMMA_NAME // Used in: pick_002
	: COMMA pick_001 NAME
	| %empty
	;
pick_002 // Used in: varargslist
	: STAR NAME opt_COMMA_NAME
	| pick_001 NAME
	;
star_COMMA_fpdef // Used in: varargslist, star_COMMA_fpdef
	: star_COMMA_fpdef COMMA fpdef opt_EQUAL_test
	| %empty
	;
opt_COMMA // Used in: varargslist
	: COMMA
	| %empty
	;
fpdef // Used in: varargslist, star_fpdef_COMMA, star_COMMA_fpdef, fplist, star_fpdef_notest
	: NAME
	| LPAR fplist RPAR
	;
fplist // Used in: fpdef
	: fpdef star_fpdef_notest COMMA
	| fpdef star_fpdef_notest
	;
star_fpdef_notest // Used in: fplist, star_fpdef_notest
	: star_fpdef_notest COMMA fpdef
	| %empty
	;
stmt // Used in: pick_NEWLINE_stmt, plus_stmt
	: simple_stmt
	| compound_stmt
	;
simple_stmt // Used in: single_input, stmt, suite
	: small_stmt star_SEMI_small_stmt SEMI NEWLINE
	| small_stmt star_SEMI_small_stmt NEWLINE
	;
star_SEMI_small_stmt // Used in: simple_stmt, star_SEMI_small_stmt
	: star_SEMI_small_stmt SEMI small_stmt
	| %empty
	;
small_stmt // Used in: simple_stmt, star_SEMI_small_stmt
	: expr_stmt
	| print_stmt
	| del_stmt
	| pass_stmt
	| flow_stmt
	| import_stmt
	| global_stmt
	| exec_stmt
	| assert_stmt
	;
expr_stmt // Used in: small_stmt, expr_stmt
	: testlist
	| expr_stmt EQUAL testlist
	;
print_stmt // Used in: small_stmt
	: PRINT star_test_COMMA test
	| PRINT star_test_COMMA
	;
star_test_COMMA // Used in: print_stmt, star_test_COMMA
	: star_test_COMMA test COMMA
	| %empty
	;
del_stmt // Used in: small_stmt
	: DEL exprlist
	;
pass_stmt // Used in: small_stmt
	: PASS
	;
flow_stmt // Used in: small_stmt
	: break_stmt
	| continue_stmt
	| return_stmt
	| raise_stmt
	;
break_stmt // Used in: flow_stmt
	: BREAK
	;
continue_stmt // Used in: flow_stmt
	: CONTINUE
	;
return_stmt // Used in: flow_stmt
	: RETURN testlist
	| RETURN
	;
raise_stmt // Used in: flow_stmt
	: RAISE test opt_test_3
	| RAISE
	;
opt_COMMA_test // Used in: opt_test_3, exec_stmt, except_clause
	: COMMA test
	| %empty
	;
opt_test_3 // Used in: raise_stmt
	: COMMA test opt_COMMA_test
	| %empty
	;
import_stmt // Used in: small_stmt
	: IMPORT dotted_name star_COMMA_dotted_name
	| FROM dotted_name IMPORT pick_STAR_NAME
	;
star_COMMA_dotted_name // Used in: import_stmt, star_COMMA_dotted_name
	: star_COMMA_dotted_name COMMA dotted_name
	| %empty
	;
star_COMMA_NAME // Used in: star_COMMA_NAME, pick_STAR_NAME, global_stmt
	: star_COMMA_NAME COMMA NAME
	| %empty
	;
pick_STAR_NAME // Used in: import_stmt
	: STAR
	| NAME star_COMMA_NAME
	;
dotted_name // Used in: import_stmt, star_COMMA_dotted_name, dotted_name
	: NAME
	| dotted_name DOT NAME
	;
global_stmt // Used in: small_stmt
	: GLOBAL NAME star_COMMA_NAME
	;
exec_stmt // Used in: small_stmt
	: EXEC expr IN test opt_COMMA_test
	| EXEC expr
	;
assert_stmt // Used in: small_stmt
	: ASSERT test COMMA test
	| ASSERT test
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
	: FOR exprlist IN testlist COLON suite ELSE COLON suite
	| FOR exprlist IN testlist COLON suite
	;
try_stmt // Used in: compound_stmt
	: TRY COLON suite plus_except opt_ELSE
	| TRY COLON suite FINALLY COLON suite
	;
plus_except // Used in: try_stmt, plus_except
	: plus_except except_clause COLON suite
	| except_clause COLON suite
	;
opt_ELSE // Used in: try_stmt
	: ELSE COLON suite
	| %empty
	;
except_clause // Used in: plus_except
	: EXCEPT test opt_COMMA_test
	| EXCEPT
	;
suite // Used in: funcdef, if_stmt, star_ELIF, while_stmt, for_stmt, try_stmt, plus_except, opt_ELSE, classdef
	: simple_stmt
	| NEWLINE INDENT plus_stmt DEDENT
	;
plus_stmt // Used in: suite, plus_stmt
	: plus_stmt stmt
	| stmt
	;
test // Used in: opt_EQUAL_test, print_stmt, star_test_COMMA, raise_stmt, opt_COMMA_test, opt_test_3, exec_stmt, assert_stmt, if_stmt, star_ELIF, while_stmt, except_clause, lambdef, subscript, opt_test_only, sliceop, testlist, star_COMMA_test, dictmaker, star_test_COLON_test, argument
	: and_test star_OR_and_test
	| lambdef
	;
star_OR_and_test // Used in: test, star_OR_and_test
	: star_OR_and_test OR and_test
	| %empty
	;
and_test // Used in: test, star_OR_and_test, and_test
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
	| EQEQUAL
	| GREATEREQUAL
	| LESSEQUAL
	| GRLT
	| NOTEQUAL
	| IN
	| NOT IN
	| IS
	| IS NOT
	;
expr // Used in: exec_stmt, comparison, expr, exprlist, star_COMMA_expr
	: xor_expr
	| expr BAR xor_expr
	;
xor_expr // Used in: expr, xor_expr
	: and_expr
	| xor_expr CIRCUMFLEX and_expr
	;
and_expr // Used in: xor_expr, and_expr
	: shift_expr
	| and_expr AMPERSAND shift_expr
	;
shift_expr // Used in: and_expr, shift_expr
	: arith_expr
	| shift_expr pick_LEFTSHIFT_RIGHTSHIFT arith_expr
	;
pick_LEFTSHIFT_RIGHTSHIFT // Used in: shift_expr
	: LEFTSHIFT
	| RIGHTSHIFT
	;
arith_expr // Used in: shift_expr, arith_expr
	: term
	| arith_expr pick_PLUS_MINUS term
	;
pick_PLUS_MINUS // Used in: arith_expr
	: PLUS
	| MINUS
	;
term // Used in: arith_expr, term
	: factor
	| term pick_old_multop factor
	;
pick_old_multop // Used in: term
	: STAR
	| SLASH
	| PERCENT
	;
factor // Used in: term, factor, star_DOUBLESTAR_factor
	: pick_unop factor
	| power
	;
pick_unop // Used in: factor
	: PLUS
	| MINUS
	| TILDE
	;
power // Used in: factor
	: atom star_trailer star_DOUBLESTAR_factor
	;
star_trailer // Used in: power, star_trailer
	: star_trailer trailer
	| %empty
	;
star_DOUBLESTAR_factor // Used in: power, star_DOUBLESTAR_factor
	: star_DOUBLESTAR_factor DOUBLESTAR factor
	| %empty
	;
atom // Used in: power
	: LPAR opt_testlist RPAR
	| LSQB opt_testlist RSQB
	| LBRACE opt_dictmaker RBRACE
	| BACKQUOTE testlist BACKQUOTE
	| NAME
	| NUMBER
	| plus_STRING
	;
opt_testlist // Used in: atom
	: testlist
	| %empty
	;
opt_dictmaker // Used in: atom
	: dictmaker
	| %empty
	;
plus_STRING // Used in: atom, plus_STRING
	: plus_STRING STRING
	| STRING
	;
lambdef // Used in: test
	: LAMBDA varargslist COLON test
	| LAMBDA COLON test
	;
trailer // Used in: star_trailer
	: LPAR opt_arglist RPAR
	| LSQB subscriptlist RSQB
	| DOT NAME
	;
opt_arglist // Used in: trailer
	: arglist
	| %empty
	;
subscriptlist // Used in: trailer
	: subscript star_COMMA_subscript COMMA
	| subscript star_COMMA_subscript
	;
star_COMMA_subscript // Used in: subscriptlist, star_COMMA_subscript
	: star_COMMA_subscript COMMA subscript
	| %empty
	;
subscript // Used in: subscriptlist, star_COMMA_subscript
	: DOT DOT DOT
	| test
	| opt_test_only COLON opt_test_only opt_sliceop
	;
opt_test_only // Used in: subscript
	: test
	| %empty
	;
opt_sliceop // Used in: subscript
	: sliceop
	| %empty
	;
sliceop // Used in: opt_sliceop
	: COLON test
	| COLON
	;
exprlist // Used in: del_stmt, for_stmt
	: expr star_COMMA_expr COMMA
	| expr star_COMMA_expr
	;
star_COMMA_expr // Used in: exprlist, star_COMMA_expr
	: star_COMMA_expr COMMA expr
	| %empty
	;
testlist // Used in: eval_input, expr_stmt, return_stmt, for_stmt, atom, opt_testlist, classdef
	: test star_COMMA_test COMMA
	| test star_COMMA_test
	;
star_COMMA_test // Used in: testlist, star_COMMA_test
	: star_COMMA_test COMMA test
	| %empty
	;
dictmaker // Used in: opt_dictmaker
	: test COLON test star_test_COLON_test COMMA
	| test COLON test star_test_COLON_test
	;
star_test_COLON_test // Used in: dictmaker, star_test_COLON_test
	: star_test_COLON_test COMMA test COLON test
	| %empty
	;
classdef // Used in: compound_stmt
	: CLASS NAME LPAR testlist RPAR COLON suite
	| CLASS NAME COLON suite
	;
arglist // Used in: opt_arglist
	: argument star_COMMA_argument COMMA
	| argument star_COMMA_argument
	;
star_COMMA_argument // Used in: arglist, star_COMMA_argument
	: star_COMMA_argument COMMA argument
	| %empty
	;
argument // Used in: arglist, star_COMMA_argument
	: test EQUAL test
	| test
	;

%%

#include <stdio.h>
void yyerror (char const *s)
{
	fprintf (stderr, "%d: %s with [%s]\n", yylineno, s, yytext);
}

