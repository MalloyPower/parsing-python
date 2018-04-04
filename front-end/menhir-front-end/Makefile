
# Default Python version:
PYVER=2.7

OCAMLC=ocamlc
LEX=ocamllex
YACC=menhir

LFLAGS = # -d
YFLAGS = --infer --base parse

OBJS = parse.cmo scan.cmo main.cmo

front-end: clean run-${PYVER}

run-${PYVER}: $(OBJS)
	$(OCAMLC) -o run-${PYVER} $(OBJS)

main.cmo: main.ml scan.cmi parse.cmi

scan.ml: makescanner

makescanner:
	$(LEX) $(LFLAGS) -o scan.ml scanners/${PYVER}.mll

parse.cmo: parse.ml parse.cmi

parse.ml: makeparser
parse.mli: makeparser

makeparser: 
	$(YACC) $(YFLAGS) ebnfmacros.mly parsers/*_${PYVER}_*.mly

scan.cmi: scan.cmo

%.cmi : %.mli
	$(OCAMLC) $<

%.cmo : %.ml
	$(OCAMLC) -c $<


clean:
	$(RM) scan.ml scan.mli
	$(RM) parse.ml parse.mli
	$(RM) *.cmo *.cmi

dist: clean
	$(RM) run-* error.log
