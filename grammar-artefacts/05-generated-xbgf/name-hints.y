// 83 tokens, in alphabetical order:
%token AMPEREQUAL AMPERSAND AND AS ASSERT AT BACKQUOTE BAR BREAK CIRCUMFLEX
%token CIRCUMFLEXEQUAL CLASS COLON COMMA CONTINUE DEDENT DEF DEL DOT DOUBLESLASH
%token DOUBLESLASHEQUAL DOUBLESTAR DOUBLESTAREQUAL ELIF ELSE ENDMARKER EQEQUAL
%token EQUAL EXCEPT EXEC FINALLY FOR FROM GLOBAL GREATER GREATEREQUAL GRLT
%token IF IMPORT IN INDENT IS LAMBDA LBRACE LEFTSHIFT LEFTSHIFTEQUAL LESS
%token LESSEQUAL LPAR LSQB MINEQUAL MINUS NAME NEWLINE NOT NOTEQUAL NUMBER
%token OR PASS PERCENT PERCENTEQUAL PLUS PLUSEQUAL PRINT RAISE RBRACE RETURN
%token RIGHTSHIFT RIGHTSHIFTEQUAL RPAR RSQB SEMI SLASH SLASHEQUAL STAR STAREQUAL
%token STRING TILDE TRY VBAREQUAL WHILE WITH YIELD

%%
// Name hints


star_NEWLINE_stmt 
	: star_NEWLINE_stmt pick_NEWLINE_stmt
	| %empty
	;

star_fpdef_notest 
	: star_fpdef_notest COMMA fpdef
	| %empty
	;
star_ELIF 
	: star_ELIF ELIF test COLON suite
	| %empty
	;
plus_except 
	: plus_except except_clause COLON suite
	| except_clause COLON suite
	;
star_test_COLON_test 
	: star_test_COLON_test COMMA test COLON test
	| %empty
	;

opt_test_2 : plus_COMMA_test opt_COMMA | %empty ;
opt_test_3 : COMMA test opt_COMMA_test | %empty ;
opt_ELSE : ELSE COLON suite | %empty ;
opt_FINALLY : FINALLY COLON suite | %empty ;
opt_AS_COMMA : pick_AS_COMMA test | %empty ;
opt_test_0 : test opt_AS_COMMA | %empty ;
opt_IF_ELSE : IF or_test ELSE test | %empty ;
opt_test_only : test | %empty ;
opt_DOUBLESTAR_test : COMMA DOUBLESTAR test | %empty ;
opt_DOUBLESTAR_NAME : COMMA DOUBLESTAR NAME | %empty ;

// 2.5 and 2.6 only:
opt_yield_test_gexp : pick_yield_expr_testlist_gexp | %empty ;
// 2.7 and after:
opt_yield_test : pick_yield_expr_testlist_comp | %empty ;

// 2.4.3 only: 
opt_par_for : LPAR gen_for RPAR | %empty ;

pick_STAR_import : STAR | LPAR import_as_names RPAR | import_as_names;
pick_for_test : comp_for | star_COMMA_test opt_COMMA;
pick_STAR_DOUBLESTAR : STAR NAME opt_DOUBLESTAR_NAME | DOUBLESTAR NAME;
pick_unop : PLUS | MINUS | TILDE;

pick_multop : STAR | SLASH | PERCENT | DOUBLESLASH;
// 2.0 and before:
pick_old_multop : STAR | SLASH | PERCENT ;

// 2.5 and before:
pick_argument_short : argument opt_COMMA  | STAR test opt_DOUBLESTAR_test | DOUBLESTAR test ;
// 2.6 and 2.7:
pick_argument : argument opt_COMMA | STAR test star_COMMA_argument  opt_DOUBLESTAR_test | DOUBLESTAR test;


// All the following are v3 only:

// 3.0-3.3
pick_for_test_test : comp_for | star_test_COLON_test opt_COMMA ;

opt_DOUBLESTAR_vfpdef : COMMA DOUBLESTAR vfpdef | %empty ;
star_expr_expr : star_expr_expr COMMA pick_expr_star_expr | %empty ;
opt_STAR_DOUBLESTAR_tfpdef : pick_STAR_DOUBLESTAR_tfpdef | %empty ;
pick_v3_multop : STAR | AT | SLASH | PERCENT | DOUBLESLASH ;
pick_func_with_for : funcdef | with_stmt | for_stmt ;
pick_test_DOUBLESTAR : test COLON test | DOUBLESTAR expr ;
pick_STAR_DOUBLESTAR_tfpdef : STAR opt_tfpdef star_COMMA_tfpdef opt_DOUBLESTAR_tfpdef | DOUBLESTAR tfpdef ;
pick_for_DOUBLESTAR : comp_for | star_test_DOUBLESTAR opt_COMMA ;
pick_class_func : classdef | funcdef | async_funcdef ;
opt_COMMA_vfpdef : COMMA opt_STAR_DOUBLESTAR_vfpdef | %empty ;
opt_COMMA_tfpdef : COMMA opt_STAR_DOUBLESTAR_tfpdef | %empty ;
opt_STAR_DOUBLESTAR_vfpdef : pick_STAR_DOUBLESTAR_vfpdef | %empty ;
star_test_DOUBLESTAR : star_test_DOUBLESTAR COMMA pick_test_DOUBLESTAR | %empty ;
opt_DOUBLESTAR_tfpdef : COMMA DOUBLESTAR tfpdef | %empty ;
pick_STAR_DOUBLESTAR_vfpdef : STAR opt_vfpdef star_COMMA_vfpdef opt_DOUBLESTAR_vfpdef | DOUBLESTAR vfpdef ;
plus_DOT_THREE_DOTS : plus_DOT_THREE_DOTS pick_DOT_THREE_DOTS | pick_DOT_THREE_DOTS ;
star_DOT_THREE_DOTS : star_DOT_THREE_DOTS pick_DOT_THREE_DOTS | %empty ;
opt_COMMA : COMMA | %empty ;


// 3.6 only: tfpdef => opt_001 -> pick_002 -> opt_003 -> opt_004
opt_COMMA_DOUBLESTAR_tfpdef : COMMA opt_DOUBLESTAR_tfpdef | %empty ;
pick_STAR_DOUBLESTAR_tfpdef : STAR opt_tfpdef star_COMMA_tfpdef opt_COMMA_DOUBLESTAR_tfpdef | DOUBLESTAR tfpdef opt_COMMA ;
opt_STAR_DOUBLESTAR_tfpdef : pick_STAR_DOUBLESTAR_tfpdef | %empty ;
opt_COMMA_tfpdef : COMMA opt_STAR_DOUBLESTAR_tfpdef | %empty ;

// 3.6 only: vpdef => opt_005 -> pick_006 -> opt_007 -> opt_008
opt_COMMA_DOUBLESTAR_vfpdef : COMMA opt_DOUBLESTAR_vfpdef | %empty ;
pick_STAR_DOUBLESTAR_vfpdef : STAR opt_vfpdef star_COMMA_vfpdef opt_COMMA_DOUBLESTAR_vfpdef | DOUBLESTAR vfpdef opt_COMMA ;
opt_STAR_DOUBLESTAR_vfpdef : pick_STAR_DOUBLESTAR_vfpdef | %empty ;
opt_COMMA_vfpdef : COMMA opt_STAR_DOUBLESTAR_vfpdef | %empty ;


%%
