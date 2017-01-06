@contributor{Vadim Zaytsev - vadim@grammarware.net - UvA}
module extract::ANTLR4


start syntax ANTLR4Grammar = //DOC_COMMENT?
		GrammarType Id name ";"
		PrequelConstruct*
		RuleSpec* rs
		ModeSpec* ;
syntax GrammarType = ("lexer" | "parser")? "grammar";
lexical Id = [a-zA-Z_01-9]+ !>> [a-zA-Z_01-9];
syntax PrequelConstruct = OptionsSpec
	|	DelegateGrammars
	|	TokensSpec
	|	Action
	;
syntax OptionsSpec = "options" "{" (Option ";")* "}";
syntax Option = Id "=" OptionValue;
syntax OptionValue = Id ("." Id)*
	|	STRING_LITERAL
	|	ACTION
	|	INT
	;

lexical STRING_LITERAL = [\'] (ESC_SEQ | ![\'\r\n\\])* [\'];
lexical ESC_SEQ = [\\][btnfru\"\'\\];
lexical ACTION = [{] ACTIONEL* [}];
lexical ACTIONEL = ![}] | ACTION;
lexical INT = [0-9]+ !>> [0-9];

syntax DelegateGrammars = "import" {DelegateGrammar ","}+ ";" ;
syntax DelegateGrammar = Id ("=" Id)?;

lexical BLOCK_COMMENT = [/][*] BCEL* [*][/];
lexical BCEL = ![*] | [*] !>> [/];
lexical LINE_COMMENT = [/][/] ![\n]* [\n];
lexical LAYOUT = [\t-\n \r \  ] | LINE_COMMENT | BLOCK_COMMENT ;
layout ANTLR4Layout = LAYOUT* !>> [\t-\n \r \  ] !>> "//" !>> "/*";

syntax TokensSpec = "tokens" "{" {Id ","}+ "}";
syntax Action = "@" (Id "::")? Id ACTION;
//syntax ActionScopeName = Id ;//| "lexer" | "parser";
syntax ModeSpec = "mode" Id ";" LexerRule*;
syntax RuleSpec = ParserRuleSpec ; // | LexerRule;
syntax LexerRule = "fragment"? Id ":" {LexerAlt "|"}+ ";" ;
syntax LexerAlt = LexerElement+ LexerCommands?;
syntax LexerElement = LabeledLexerElement EbnfSuffix?
	|	LexerAtom EbnfSuffix?
	|	LexerBlock EbnfSuffix?
	|	ACTION "?"?
	;
syntax LexerBlock = "(" {LexerAlt "|"}+ ")";
syntax LabeledLexerElement = Id ("=" | "+=") (LexerAtom | Block);
syntax LexerAtom = Range
	|	(Id | STRING_LITERAL) ElementOptions?
	//| Id ARG_ACTION? ElementOptions?
	| "~" (SetElement | BlockSet)
	| LEXER_CHAR_SET
	| "." ElementOptions?
	;
lexical LEXER_CHAR_SET = [\[] LCCHAR* [\]];
lexical LCCHAR = ![\\\]] | [\\] ![];
//[\]\[a-zA-Z\"\'\\\-];
//: ~[\r\n\u2028\u2029\]\\]
//~[\r\n\u2028\u2029*\\/\[]

syntax ParserRuleSpec = RuleModifier* Id ARG_ACTION?
        RuleReturns? ThrowsSpec? LocalsSpec?
		RulePrequel*
		":" RuleBlock LexerCommands? // lexerCommands is not here in the original
		";" ExceptionGroup;
syntax RuleModifier = "public" | "private" | "protected" | "fragment";
syntax RuleReturns = "returns" ARG_ACTION;
syntax ThrowsSpec = "throws" {Id ","}+;
syntax LocalsSpec = "locals" ARG_ACTION	;
syntax RulePrequel = OptionsSpec | RuleAction;
syntax ExceptionGroup = ("catch" ARG_ACTION ACTION)* ("finally" ACTION)?;
syntax RuleBlock = {LabeledAlt "|"}+ ;
syntax LabeledAlt = Alternative ("#" Id)?;
syntax Alternative = ElementOptions? Element*;
syntax ElementOptions = "\<" {ElementOption ","}+ "\>";
syntax Element
	= LabeledElement EbnfSuffix?
	| Atom EbnfSuffix?
	| Ebnf
	| ACTION "?"?
	;
syntax ElementOption = Id ("=" (Id | STRING_LITERAL))?;
syntax LabeledElement = Id ("=" | "+=") (Atom | Block);
syntax Ebnf = Block EbnfSuffix?;
syntax EbnfSuffix = ("?" | "*" | "+") "?"?;
syntax RuleAction = "@" Id ACTION;

syntax Atom
	= Range
	| STRING_LITERAL ElementOptions?
	| Id ARG_ACTION? ElementOptions?
	| "~" (SetElement | BlockSet)
	| "." ElementOptions?
	;
syntax Range = STRING_LITERAL ".." STRING_LITERAL;
syntax SetElement = Id ElementOptions?
	|	STRING_LITERAL ElementOptions?
	|	Range
	|	LEXER_CHAR_SET;
syntax Block = "(" ( OptionsSpec? RuleAction* ":" )? AltList ")";
syntax AltList = {Alternative "|"}+;
syntax BlockSet = "(" {SetElement "|"}+ ")";

// E.g., channel(HIDDEN), skip, more, mode(INSIDE), push(INSIDE), pop
syntax LexerCommands = "-\>" {LexerCommand ","}+;
syntax LexerCommand = (Id | "mode") ( "(" (Id | INT) ")" )?;

// [int x, List<String> a[]]
lexical ARG_ACTION = BOXEDISLAND; 
lexical BOXEDISLAND = [\[] AACHAR* [\]];
lexical AACHAR = ![\[\]] | ARG_ACTION;

