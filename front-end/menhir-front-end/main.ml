(**************************************************************************)
(* This code was adapted from the OCaml distribution                      *)
(* originally by Xavier Leroy, projet Cristal, INRIA Rocquencourt         *)
(* Thus I repeat the original copyright notice here:                      *)
(*                                                                        *)
(*   Copyright 1996 Institut National de Recherche en Informatique et     *)
(*     en Automatique.                                                    *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

(* Command-line parsing. *)

open Scan
open Parse

let print_error lexbuf msg = 
  let endpos = (Lexing.lexeme_end_p lexbuf) in
  let real_col = endpos.Lexing.pos_cnum - endpos.Lexing.pos_bol in
  let full_msg = (Printf.sprintf "%d (col %d): %s with [%s]." endpos.Lexing.pos_lnum real_col msg (Lexing.lexeme lexbuf)) in
  prerr_endline full_msg;
  exit 2

let main () =
  let ic = ref stdin in 
  if Array.length Sys.argv >= 2 then begin
    let source_name = Sys.argv.(1) in
      ic := open_in source_name;
  end;
  let lexbuf = Lexing.from_channel !ic in
  let parse_output =
    try
      Parse.start Scan.yylex lexbuf
    with
      Parse.Error ->
        print_error lexbuf "Syntax error";
    | Scan.Lexical_error msg ->
        print_error lexbuf (Printf.sprintf "Lexical Error - %s" msg);
  in
  close_in !ic;
  parse_output

let _ = main(); exit 0
