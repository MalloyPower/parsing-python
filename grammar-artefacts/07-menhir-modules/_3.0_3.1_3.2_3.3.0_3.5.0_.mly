// Grammar for versions:    3.0    3.1    3.2  3.3.0  3.5.0       
// Generated by CompareGrammar on 2018-01-16 at 20:21:38.878+00:00


// Top non-terminals: comp_for expr_stmt


%%

%public
expr_stmt:
	  testlist_star_expr _choice(augassign _choice(yield_expr | testlist {}) | _star(EQUAL _choice(yield_expr | testlist_star_expr {}) {}) {})
	{} ;

%public
comp_for:
	  FOR exprlist IN or_test _optional(comp_iter {})
	{} ;


%%


