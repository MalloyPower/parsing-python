// Generated (bisonified) from 3.5.0.txt on 2016-11-23 at 16:45:51 +0000

%{
	int yylex (void);
	extern int yylineno;
	extern char *yytext;
	void yyerror (char const *);
%}

// 89 tokens, in alphabetical order:
%token AMPEREQUAL AMPERSAND AND ARROW AS ASSERT ASYNC AT ATEQ AWAIT BAR
%token BREAK CIRCUMFLEX CIRCUMFLEXEQUAL CLASS COLON COMMA CONTINUE DEDENT
%token DEF DEL DOT DOUBLESLASH DOUBLESLASHEQUAL DOUBLESTAR DOUBLESTAREQUAL
%token ELIF ELSE ENDMARKER EQEQUAL EQUAL EXCEPT FALSE FINALLY FOR FROM GLOBAL
%token GREATER GREATEREQUAL GRLT IF IMPORT IN INDENT IS LAMBDA LBRACE LEFTSHIFT
%token LEFTSHIFTEQUAL LESS LESSEQUAL LPAR LSQB MINEQUAL MINUS NAME NEWLINE
%token NONE NONLOCAL NOT NOTEQUAL NUMBER OR PASS PERCENT PERCENTEQUAL PLUS
%token PLUSEQUAL RAISE RBRACE RETURN RIGHTSHIFT RIGHTSHIFTEQUAL RPAR RSQB
%token SEMI SLASH SLASHEQUAL STAR STAREQUAL STRING THREE_DOTS TILDE TRUE
%token TRY VBAREQUAL WHILE WITH YIELD

%start start


%%

start
	: file_input
	| eval_input
	| encoding_decl
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
decorator // Used in: decorators
	: AT dotted_name LPAR opt_arglist RPAR NEWLINE
	| AT dotted_name NEWLINE
	;
opt_arglist // Used in: decorator, trailer, classdef
	: arglist
	| %empty
	;
decorators // Used in: decorators, decorated
	: decorators decorator
	| decorator
	;
decorated // Used in: compound_stmt
	: decorators pick_class_func
	;
pick_class_func // Used in: decorated
	: classdef
	| funcdef
	| async_funcdef
	;
async_funcdef // Used in: pick_class_func
	: ASYNC funcdef
	;
funcdef // Used in: pick_class_func, async_funcdef, compound_stmt, pick_func_with_for
	: DEF NAME parameters ARROW test COLON suite
	| DEF NAME parameters COLON suite
	;
parameters // Used in: funcdef
	: LPAR typedargslist RPAR
	| LPAR RPAR
	;
typedargslist // Used in: parameters
	: tfpdef opt_EQUAL_test star_COMMA_tfpdef opt_COMMA_tfpdef
	| STAR opt_tfpdef star_COMMA_tfpdef opt_DOUBLESTAR_tfpdef
	| DOUBLESTAR tfpdef
	;
opt_EQUAL_test // Used in: typedargslist, star_COMMA_tfpdef, varargslist, star_COMMA_vfpdef
	: EQUAL test
	| %empty
	;
star_COMMA_tfpdef // Used in: typedargslist, star_COMMA_tfpdef, pick_STAR_DOUBLESTAR_tfpdef
	: star_COMMA_tfpdef COMMA tfpdef opt_EQUAL_test
	| %empty
	;
opt_tfpdef // Used in: typedargslist, pick_STAR_DOUBLESTAR_tfpdef
	: tfpdef
	| %empty
	;
opt_DOUBLESTAR_tfpdef // Used in: typedargslist, pick_STAR_DOUBLESTAR_tfpdef
	: COMMA DOUBLESTAR tfpdef
	| %empty
	;
pick_STAR_DOUBLESTAR_tfpdef // Used in: opt_STAR_DOUBLESTAR_tfpdef
	: STAR opt_tfpdef star_COMMA_tfpdef opt_DOUBLESTAR_tfpdef
	| DOUBLESTAR tfpdef
	;
opt_STAR_DOUBLESTAR_tfpdef // Used in: opt_COMMA_tfpdef
	: pick_STAR_DOUBLESTAR_tfpdef
	| %empty
	;
opt_COMMA_tfpdef // Used in: typedargslist
	: COMMA opt_STAR_DOUBLESTAR_tfpdef
	| %empty
	;
tfpdef // Used in: typedargslist, star_COMMA_tfpdef, opt_tfpdef, opt_DOUBLESTAR_tfpdef, pick_STAR_DOUBLESTAR_tfpdef
	: NAME COLON test
	| NAME
	;
varargslist // Used in: lambdef, lambdef_nocond
	: vfpdef opt_EQUAL_test star_COMMA_vfpdef opt_COMMA_vfpdef
	| STAR opt_vfpdef star_COMMA_vfpdef opt_DOUBLESTAR_vfpdef
	| DOUBLESTAR vfpdef
	;
star_COMMA_vfpdef // Used in: varargslist, star_COMMA_vfpdef, pick_STAR_DOUBLESTAR_vfpdef
	: star_COMMA_vfpdef COMMA vfpdef opt_EQUAL_test
	| %empty
	;
opt_vfpdef // Used in: varargslist, pick_STAR_DOUBLESTAR_vfpdef
	: vfpdef
	| %empty
	;
opt_DOUBLESTAR_vfpdef // Used in: varargslist, pick_STAR_DOUBLESTAR_vfpdef
	: COMMA DOUBLESTAR vfpdef
	| %empty
	;
pick_STAR_DOUBLESTAR_vfpdef // Used in: opt_STAR_DOUBLESTAR_vfpdef
	: STAR opt_vfpdef star_COMMA_vfpdef opt_DOUBLESTAR_vfpdef
	| DOUBLESTAR vfpdef
	;
opt_STAR_DOUBLESTAR_vfpdef // Used in: opt_COMMA_vfpdef
	: pick_STAR_DOUBLESTAR_vfpdef
	| %empty
	;
opt_COMMA_vfpdef // Used in: varargslist
	: COMMA opt_STAR_DOUBLESTAR_vfpdef
	| %empty
	;
vfpdef // Used in: varargslist, star_COMMA_vfpdef, opt_vfpdef, opt_DOUBLESTAR_vfpdef, pick_STAR_DOUBLESTAR_vfpdef
	: NAME
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
	| del_stmt
	| pass_stmt
	| flow_stmt
	| import_stmt
	| global_stmt
	| nonlocal_stmt
	| assert_stmt
	;
expr_stmt // Used in: small_stmt
	: testlist_star_expr pick_augassign
	;
pick_yield_expr_testlist // Used in: pick_augassign
	: yield_expr
	| testlist
	;
pick_yield_expr_testlist_star_expr // Used in: star_EQUAL
	: yield_expr
	| testlist_star_expr
	;
star_EQUAL // Used in: star_EQUAL, pick_augassign
	: star_EQUAL EQUAL pick_yield_expr_testlist_star_expr
	| %empty
	;
pick_augassign // Used in: expr_stmt
	: augassign pick_yield_expr_testlist
	| star_EQUAL
	;
testlist_star_expr // Used in: expr_stmt, pick_yield_expr_testlist_star_expr
	: pick_test_star_expr star_COMMA opt_COMMA
	;
pick_test_star_expr // Used in: testlist_star_expr, star_COMMA, testlist_comp, dictorsetmaker
	: test
	| star_expr
	;
star_COMMA // Used in: testlist_star_expr, star_COMMA, pick_comp_for
	: star_COMMA COMMA pick_test_star_expr
	| %empty
	;
opt_COMMA // Used in: testlist_star_expr, pick_comp_for, exprlist, pick_for_DOUBLESTAR
	: COMMA
	| %empty
	;
augassign // Used in: pick_augassign
	: PLUSEQUAL
	| MINEQUAL
	| STAREQUAL
	| ATEQ
	| SLASHEQUAL
	| PERCENTEQUAL
	| AMPEREQUAL
	| VBAREQUAL
	| CIRCUMFLEXEQUAL
	| LEFTSHIFTEQUAL
	| RIGHTSHIFTEQUAL
	| DOUBLESTAREQUAL
	| DOUBLESLASHEQUAL
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
	| yield_stmt
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
yield_stmt // Used in: flow_stmt
	: yield_expr
	;
raise_stmt // Used in: flow_stmt
	: RAISE test opt_FROM_test
	| RAISE
	;
opt_FROM_test // Used in: raise_stmt
	: FROM test
	| %empty
	;
import_stmt // Used in: small_stmt
	: import_name
	| import_from
	;
import_name // Used in: import_stmt
	: IMPORT dotted_as_names
	;
import_from // Used in: import_stmt
	: FROM pick_dotted_name IMPORT pick_STAR_import
	;
pick_DOT_THREE_DOTS // Used in: star_DOT_THREE_DOTS, plus_DOT_THREE_DOTS
	: DOT
	| THREE_DOTS
	;
star_DOT_THREE_DOTS // Used in: star_DOT_THREE_DOTS, pick_dotted_name
	: star_DOT_THREE_DOTS pick_DOT_THREE_DOTS
	| %empty
	;
plus_DOT_THREE_DOTS // Used in: plus_DOT_THREE_DOTS, pick_dotted_name
	: plus_DOT_THREE_DOTS pick_DOT_THREE_DOTS
	| pick_DOT_THREE_DOTS
	;
pick_dotted_name // Used in: import_from
	: star_DOT_THREE_DOTS dotted_name
	| plus_DOT_THREE_DOTS
	;
pick_STAR_import // Used in: import_from
	: STAR
	| LPAR import_as_names RPAR
	| import_as_names
	;
import_as_name // Used in: import_as_names, star_COMMA_import_as_name
	: NAME AS NAME
	| NAME
	;
dotted_as_name // Used in: dotted_as_names
	: dotted_name AS NAME
	| dotted_name
	;
import_as_names // Used in: pick_STAR_import
	: import_as_name star_COMMA_import_as_name COMMA
	| import_as_name star_COMMA_import_as_name
	;
star_COMMA_import_as_name // Used in: import_as_names, star_COMMA_import_as_name
	: star_COMMA_import_as_name COMMA import_as_name
	| %empty
	;
dotted_as_names // Used in: import_name, dotted_as_names
	: dotted_as_name
	| dotted_as_names COMMA dotted_as_name
	;
dotted_name // Used in: decorator, pick_dotted_name, dotted_as_name, dotted_name
	: NAME
	| dotted_name DOT NAME
	;
global_stmt // Used in: small_stmt
	: GLOBAL NAME star_COMMA_NAME
	;
star_COMMA_NAME // Used in: global_stmt, star_COMMA_NAME, nonlocal_stmt
	: star_COMMA_NAME COMMA NAME
	| %empty
	;
nonlocal_stmt // Used in: small_stmt
	: NONLOCAL NAME star_COMMA_NAME
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
	| with_stmt
	| funcdef
	| classdef
	| decorated
	| async_stmt
	;
async_stmt // Used in: compound_stmt
	: ASYNC pick_func_with_for
	;
pick_func_with_for // Used in: async_stmt
	: funcdef
	| with_stmt
	| for_stmt
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
for_stmt // Used in: compound_stmt, pick_func_with_for
	: FOR exprlist IN testlist COLON suite ELSE COLON suite
	| FOR exprlist IN testlist COLON suite
	;
try_stmt // Used in: compound_stmt
	: TRY COLON suite plus_except opt_ELSE opt_FINALLY
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
opt_FINALLY // Used in: try_stmt
	: FINALLY COLON suite
	| %empty
	;
with_stmt // Used in: compound_stmt, pick_func_with_for
	: WITH with_item star_COMMA_with_item COLON suite
	;
star_COMMA_with_item // Used in: with_stmt, star_COMMA_with_item
	: star_COMMA_with_item COMMA with_item
	| %empty
	;
with_item // Used in: with_stmt, star_COMMA_with_item
	: test AS expr
	| test
	;
except_clause // Used in: plus_except
	: EXCEPT test opt_AS_NAME
	| EXCEPT
	;
opt_AS_NAME // Used in: except_clause
	: AS NAME
	| %empty
	;
suite // Used in: funcdef, if_stmt, star_ELIF, while_stmt, for_stmt, try_stmt, plus_except, opt_ELSE, opt_FINALLY, with_stmt, classdef
	: simple_stmt
	| NEWLINE INDENT plus_stmt DEDENT
	;
plus_stmt // Used in: suite, plus_stmt
	: plus_stmt stmt
	| stmt
	;
test // Used in: funcdef, opt_EQUAL_test, tfpdef, pick_test_star_expr, raise_stmt, opt_FROM_test, assert_stmt, if_stmt, star_ELIF, while_stmt, with_item, except_clause, opt_IF_ELSE, lambdef, subscript, opt_test_only, sliceop, testlist, star_COMMA_test, pick_test_DOUBLESTAR, argument, yield_arg
	: or_test opt_IF_ELSE
	| lambdef
	;
opt_IF_ELSE // Used in: test
	: IF or_test ELSE test
	| %empty
	;
test_nocond // Used in: lambdef_nocond, comp_if
	: or_test
	| lambdef_nocond
	;
lambdef // Used in: test
	: LAMBDA varargslist COLON test
	| LAMBDA COLON test
	;
lambdef_nocond // Used in: test_nocond
	: LAMBDA varargslist COLON test_nocond
	| LAMBDA COLON test_nocond
	;
or_test // Used in: test, opt_IF_ELSE, test_nocond, or_test, comp_for
	: and_test
	| or_test OR and_test
	;
and_test // Used in: or_test, and_test
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
star_expr // Used in: pick_test_star_expr, pick_expr_star_expr
	: STAR expr
	;
expr // Used in: with_item, comparison, star_expr, expr, pick_expr_star_expr, pick_test_DOUBLESTAR
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
	| term pick_v3_multop factor
	;
pick_v3_multop // Used in: term
	: STAR
	| AT
	| SLASH
	| PERCENT
	| DOUBLESLASH
	;
factor // Used in: term, factor, power
	: pick_unop factor
	| power
	;
pick_unop // Used in: factor
	: PLUS
	| MINUS
	| TILDE
	;
power // Used in: factor
	: atom_expr DOUBLESTAR factor
	| atom_expr
	;
atom_expr // Used in: power
	: AWAIT atom star_trailer
	| atom star_trailer
	;
star_trailer // Used in: atom_expr, star_trailer
	: star_trailer trailer
	| %empty
	;
atom // Used in: atom_expr
	: LPAR opt_yield_test RPAR
	| LSQB opt_testlist_comp RSQB
	| LBRACE opt_dictorsetmaker RBRACE
	| NAME
	| NUMBER
	| plus_STRING
	| THREE_DOTS
	| NONE
	| TRUE
	| FALSE
	;
pick_yield_expr_testlist_comp // Used in: opt_yield_test
	: yield_expr
	| testlist_comp
	;
opt_yield_test // Used in: atom
	: pick_yield_expr_testlist_comp
	| %empty
	;
opt_testlist_comp // Used in: atom
	: testlist_comp
	| %empty
	;
opt_dictorsetmaker // Used in: atom
	: dictorsetmaker
	| %empty
	;
plus_STRING // Used in: atom, plus_STRING
	: plus_STRING STRING
	| STRING
	;
testlist_comp // Used in: pick_yield_expr_testlist_comp, opt_testlist_comp
	: pick_test_star_expr pick_comp_for
	;
pick_comp_for // Used in: testlist_comp, dictorsetmaker
	: comp_for
	| star_COMMA opt_COMMA
	;
trailer // Used in: star_trailer
	: LPAR opt_arglist RPAR
	| LSQB subscriptlist RSQB
	| DOT NAME
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
	: test
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
exprlist // Used in: del_stmt, for_stmt, comp_for
	: pick_expr_star_expr star_expr_expr opt_COMMA
	;
pick_expr_star_expr // Used in: exprlist, star_expr_expr
	: expr
	| star_expr
	;
star_expr_expr // Used in: exprlist, star_expr_expr
	: star_expr_expr COMMA pick_expr_star_expr
	| %empty
	;
testlist // Used in: eval_input, pick_yield_expr_testlist, return_stmt, for_stmt, yield_arg
	: test star_COMMA_test COMMA
	| test star_COMMA_test
	;
star_COMMA_test // Used in: testlist, star_COMMA_test
	: star_COMMA_test COMMA test
	| %empty
	;
dictorsetmaker // Used in: opt_dictorsetmaker
	: pick_test_DOUBLESTAR pick_for_DOUBLESTAR
	| pick_test_star_expr pick_comp_for
	;
pick_test_DOUBLESTAR // Used in: dictorsetmaker, star_test_DOUBLESTAR
	: test COLON test
	| DOUBLESTAR expr
	;
star_test_DOUBLESTAR // Used in: star_test_DOUBLESTAR, pick_for_DOUBLESTAR
	: star_test_DOUBLESTAR COMMA pick_test_DOUBLESTAR
	| %empty
	;
pick_for_DOUBLESTAR // Used in: dictorsetmaker
	: comp_for
	| star_test_DOUBLESTAR opt_COMMA
	;
classdef // Used in: pick_class_func, compound_stmt
	: CLASS NAME LPAR opt_arglist RPAR COLON suite
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
	: test opt_comp_for
	| test EQUAL test
	| DOUBLESTAR test
	| STAR test
	;
opt_comp_for // Used in: argument
	: comp_for
	| %empty
	;
comp_iter // Used in: comp_for, comp_if
	: comp_for
	| comp_if
	;
comp_for // Used in: pick_comp_for, pick_for_DOUBLESTAR, opt_comp_for, comp_iter
	: FOR exprlist IN or_test comp_iter
	| FOR exprlist IN or_test
	;
comp_if // Used in: comp_iter
	: IF test_nocond comp_iter
	| IF test_nocond
	;
encoding_decl // Used in: start
	: NAME
	;
yield_expr // Used in: pick_yield_expr_testlist, pick_yield_expr_testlist_star_expr, yield_stmt, pick_yield_expr_testlist_comp
	: YIELD yield_arg
	| YIELD
	;
yield_arg // Used in: yield_expr
	: FROM test
	| testlist
	;

%%

#include <stdio.h>
void yyerror (char const *s)
{
	fprintf (stderr, "%d: %s with [%s]\n", yylineno, s, yytext);
}
