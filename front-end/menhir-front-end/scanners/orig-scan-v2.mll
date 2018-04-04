{
open Parse

(*** Utility routines to get current line/col number, print a token etc. ***)

exception Lexical_error of string

let tok_line lexbuf =
  let pos = (Lexing.lexeme_start_p lexbuf) in
    pos.Lexing.pos_lnum

let tok_col lexbuf =
  let pos = (Lexing.lexeme_start_p lexbuf) in
    (pos.Lexing.pos_cnum - pos.Lexing.pos_bol)

let print_token lexbuf token =
  let pt = (Lexing.lexeme lexbuf) in
  let prtok = if (token == NEWLINE) then "\\n" else pt in
  let msg = (Printf.sprintf "(line %d col %d): [%s]." (tok_line lexbuf) (tok_col lexbuf) prtok) in
  print_endline msg

let at_start_of_line lexbuf =
  (tok_col lexbuf) == 0

let lexical_error msg = 
  raise (Lexical_error msg)


(*** The lexer state ***)

let indstack = ref [0]        (* Stack of indents *)
let atbol = ref true          (* Nonzero if at begin of new line *)
let pendin = ref 0            (* Pending indents (if > 0) or dedents (if < 0) *)
let pending_token = ref None  (* Pending token, queued while processing indent/dedent *)
let level = ref 0             (* () [] {} Parentheses nesting level *)
let cont_line = ref false     (* whether we are in a continuation line. *)

let seen_future = ref false      (* Importing future module? *)
let print_is_name = ref false    (* Treat print as name? (o/w it is a token) *)

let long_string_start = ref Lexing.dummy_pos  (* Starting column for a multi-line string *)


(*** Routines to manage the lexer state ***)

let left_enclose () =
  level := !level + 1

let right_enclose () =
  level := !level - 1

let mark_long_string_start lexbuf =
  long_string_start := (Lexing.lexeme_start_p lexbuf)

let mark_long_string_end lexbuf =
  lexbuf.Lexing.lex_start_p <- !long_string_start;
  long_string_start := Lexing.dummy_pos

(* Increment line number for every newline contained in a string *)
let check_for_newlines lexbuf =
  let inc_line_num () = 
    let pos = lexbuf.Lexing.lex_curr_p in
      lexbuf.Lexing.lex_curr_p <- {pos with  Lexing.pos_lnum = pos.Lexing.pos_lnum + 1; } in
  let mark_nl c = if c=='\n' then inc_line_num () in
  let str = Lexing.lexeme lexbuf in 
  String.iter mark_nl str

(* Figure out if a newline in the input should generate a NEWLINE token *)
let explicit_newline lexbuf =
  let is_explicit_newline = (!level == 0) && (!cont_line || not (at_start_of_line lexbuf)) in
  cont_line := false; 
  Lexing.new_line lexbuf;
  is_explicit_newline

let handle_eof lexbuf =
  Lexing.new_line lexbuf;       (* Sets current indentation to 0 *)
  atbol := true   (* Triggers flushing of the indentation stack *)


(*** Indentation stack handling  ***)

(* Pop the indentation stack until you get back to col, queue DEDENTs *)
let rec pop_indents col =
  match !indstack with 
  | [] -> lexical_error (Printf.sprintf "mismatched dedent: got %d, wanted 0" col)
  | curr_indent :: tl_stack ->
    if col < curr_indent then 
      (pendin := !pendin - 1;  indstack := tl_stack; pop_indents col)
    else if (col > curr_indent) then 
      lexical_error (Printf.sprintf "mismatched dedent: expected %d spaces" curr_indent)
    (* else col == curr_indent, and we're done *)

(* Push col onto the indentation stack, queue an INDENT *)
let push_indent col =
  pendin := !pendin + 1;  
  indstack := (col :: !indstack)

(* Wrapper that calls push or pop as appropriate *)
let note_new_indent col =
  let curr_indent = List.hd !indstack in
  if col > curr_indent then push_indent col
  else if col < curr_indent then pop_indents col
  (* else col == curr_indent, so do nothing *)


}


(* ***** NUMBERS ***** *)

let digit        = ['0'-'9']
let nonzero      = ['1'-'9']
let octdigit     = ['0'-'7']
let bindigit     = ['0' '1']
let hexdigit     = ['0'-'9' 'a'-'f' 'A'-'F']

let hexinteger   = '0' ['x' 'X'] hexdigit +
let octinteger   = '0' ['o' 'O'] octdigit +| '0' octdigit +
let bininteger   = '0' ['b' 'B'] bindigit +
let nzointeger   = nonzero  digit *
let decinteger   = nzointeger | '0'
let integer      = decinteger | octinteger | hexinteger | bininteger 
let longinteger  = integer ['l' 'L']


let nzintpart    = nonzero  digit *
let intpart      = nzintpart | '0'
let fraction     = '.' digit +
let exponent     = ['e' 'E']['+' '-']? digit +
let pointfloat_1 = intpart ? fraction 
let pointfloat_2 = intpart '.'
let pointfloat   = pointfloat_1 | pointfloat_2 

let expfloat_2   = nonzero  digit *
let expfloat_1   = expfloat_2 | pointfloat 
let expfloat     = expfloat_1  exponent 
let floatnumber  = pointfloat | expfloat 

let imaghead     = floatnumber | intpart 
let imagnumber   = imaghead ['j' 'J']

let number       = integer | longinteger | floatnumber | imagnumber 

(* ***** SPACE and COMMENT ***** *)

let ws        = [' ' '\t' '\x0C']
let spaces    = ws +

let newline   = '\r'? '\n' | '\r'
let comment   = '#' [^ '\n']*

(* ***** STRINGS ***** *)

let shortchar2tck   = [^ '\n' '\r' '\"' '\\']
let shortchar1tck   = [^ '\n' '\r' '\'' '\\']
let longchar        = [^ '\\']
let escapeseq       = '\\' _ | '\\' newline

let longitem        =  longchar | escapeseq 
let longstring2tck  = "\"\"\"" longitem * "\"\"\""
let longstring1tck  = "\'\'\'" longitem * "\'\'\'"
let longstring      =  longstring1tck | longstring2tck 

let shortitem2tck   =  shortchar2tck | escapeseq 
let shortitem1tck   =  shortchar1tck | escapeseq 
let shortstring2tck = '\"' shortitem2tck * '\"'
let shortstring1tck = '\'' shortitem1tck * '\''
let shortstring     =  shortstring1tck | shortstring2tck 

let ruprefix        = ['r' 'R' 'u' 'U']['r' 'R' 'u' 'U']?
let rbprefix        = ['r' 'R' 'b' 'B']['r' 'R' 'b' 'B']?
let stringprefix    = ruprefix | rbprefix 

let stringbody      = shortstring 
let string          = stringprefix ? stringbody 

let bom_marker = '\xEF' '\xBB' '\xBF'

(* ***** IDENTIFIERS ***** *)

(* NB: this is a hack to allow names contain any Unicode characters (>127) *)
(* Change this when ocamllex gets Unicode support *)
let id_start     = ['_' 'a'-'z' 'A'-'Z' '\x80'-'\xFF']
let id_continue  = ['_' 'a'-'z' 'A'-'Z' '0'-'9' '\x80'-'\xFF']  
let name         = id_start id_continue*



(* **************************************** *)
(* ***** THE MAIN SCANNER ENTRY-POINT ***** *)
(* **************************************** *)

rule main = parse

(* Hack to allow 2.7 use 3.x print-style function call *)
| "print_function"   { print_is_name := !seen_future; NAME }
| "__future__"       { seen_future := true; NAME }

| bom_marker { if (Lexing.lexeme_start lexbuf)==0 then main lexbuf else lexical_error("unexpected BOM character") }

| comment   { main lexbuf }
| spaces    { main lexbuf }

| ws* comment? newline   { if explicit_newline lexbuf then NEWLINE else main lexbuf }

(* Explicit line joining: throw it away *) 
| "\\" newline           { cont_line := true; Lexing.new_line lexbuf; main lexbuf }

| string                 { check_for_newlines lexbuf; STRING }
| stringprefix? "'''"    { mark_long_string_start lexbuf; long_string lexbuf }
| stringprefix? "\"\"\"" { mark_long_string_start lexbuf; long_string_2 lexbuf }

| "("        { left_enclose();  LPAR }
| ")"        { right_enclose(); RPAR }
| "["        { left_enclose();  LSQB  }
| "]"        { right_enclose(); RSQB }
| "{"        { left_enclose();  LBRACE }
| "}"        { right_enclose(); RBRACE }

| ":"        { COLON }
| ","        { COMMA }
| ";"        { SEMI }

| "+"        { PLUS }
| "-"        { MINUS }
| "*"        { STAR }
| "/"        { SLASH }

| "<"        { LESS }
| ">"        { GREATER }
| "="        { EQUAL }

| "."        { DOT }
| "%"        { PERCENT }
| "`"        { BACKQUOTE }

| "=="       { EQEQUAL }
| "!="       { NOTEQUAL }
| "<="       { LESSEQUAL }
| ">="       { GREATEREQUAL }
| "<>"       { GRLT }

| "~"        { TILDE }
| "^"        { CIRCUMFLEX }
| "<<"       { LEFTSHIFT }
| ">>"       { RIGHTSHIFT }
| "**"       { DOUBLESTAR }

| "+="       { PLUSEQUAL }
| "-="       { MINEQUAL }
| "*="       { STAREQUAL }
| "/="       { SLASHEQUAL }
| "%="       { PERCENTEQUAL }
| "&="       { AMPEREQUAL }
| "|"        { BAR }
| "|="       { VBAREQUAL }
| "^="       { CIRCUMFLEXEQUAL }
| "<<="      { LEFTSHIFTEQUAL }
| ">>="      { RIGHTSHIFTEQUAL }
| "**="      { DOUBLESTAREQUAL }
| "//"       { DOUBLESLASH }
| "//="      { DOUBLESLASHEQUAL }

| "@"        { AT }

| "and"      { AND }
| "&"        { AMPERSAND }
| "not"      { NOT }
| "or"       { OR }
| "as"       { AS }
| "assert"   { ASSERT }
| "break"    { BREAK }
| "class"    { CLASS }
| "continue" { CONTINUE }
| "def"      { DEF }
| "del"      { DEL }
| "elif"     { ELIF }
| "else"     { ELSE }
| "except"   { EXCEPT }
| "exec"     { EXEC }
| "finally"  { FINALLY }
| "for"      { FOR }
| "from"     { FROM }
| "global"   { GLOBAL }
| "if"       { IF }
| "import"   { IMPORT }
| "in"       { IN }
| "is"       { IS }
| "lambda"   { LAMBDA }
| "pass"     { PASS }
| "print"    { if !print_is_name then NAME else PRINT }
| "raise"    { RAISE }
| "return"   { RETURN }
| "try"      { TRY }
| "while"    { WHILE }
| "with"     { WITH }
| "yield"    { YIELD }

| number    { NUMBER }

| name      { NAME } 
    
| eof { handle_eof lexbuf; ENDMARKER }

| _  { lexical_error("unknown character") }


and long_string = parse
| stringprefix? "'''" { mark_long_string_end lexbuf; STRING }
| newline             { Lexing.new_line lexbuf; long_string lexbuf }
| eof                 { lexical_error "unterminated single-quote long string" }
| escapeseq           { long_string lexbuf }
| _                   { long_string lexbuf }

and long_string_2 = parse
| stringprefix? "\"\"\"" { mark_long_string_end lexbuf; STRING}
| newline                { Lexing.new_line lexbuf; long_string_2 lexbuf }
| eof                    { lexical_error "unterminated double-quote long string" }
| escapeseq              { long_string_2 lexbuf }
| _                      { long_string_2 lexbuf }


(* ***** END OF RULES SECTION ***** *)

{

(*** Main external entry point: call this function to get a token ***)

let rec yylex lexbuf =
  (* First check for any pending indents or dedents *)
  if !pendin < 0 then (pendin := !pendin + 1; DEDENT)
  else if !pendin > 0 then (pendin := !pendin - 1; INDENT)
  (* Next check for a pending token *)
  else match !pending_token with
  | Some t -> (pending_token := None; t)
  (* Finally, call the actual scanner *)
  | None -> let token = main lexbuf in
    if token == NEWLINE then 
      (atbol := true; NEWLINE)
    else if !atbol then 
      (atbol := false; note_new_indent (tok_col lexbuf); pending_token := (Some token);  (yylex lexbuf))
    (* if we get here then nothing is pending, so just return the token *)
    else token

(* Debug verion: call this to print each token as you get it *)
let debug_yylex lexbuf =
  let token = yylex lexbuf in
    print_token lexbuf token;
    token

}

